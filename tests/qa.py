#!/usr/bin/env python3
"""Fieldwork 6.0 offline release audit. Not a Godot engine parser."""
import hashlib
import json
import re
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
results = []


def read(name):
    return (ROOT / name).read_text(encoding="utf-8")


def check(title, ok):
    ok = bool(ok)
    results.append((title, ok))
    print(("PASS " if ok else "FAIL ") + title)


def image_ok(p):
    raw = p.read_bytes()
    if not raw.startswith(b"\x89PNG\r\n\x1a\n"):
        return False
    offset = 8
    saw_data = False
    while offset + 12 <= len(raw):
        length = int.from_bytes(raw[offset:offset+4], "big")
        end = offset + length + 12
        if end > len(raw):
            return False
        tag = raw[offset+4:offset+8]
        data = raw[offset+8:offset+8+length]
        checksum = int.from_bytes(raw[end-4:end], "big")
        if zlib.crc32(tag + data) & 0xFFFFFFFF != checksum:
            return False
        saw_data |= tag == b"IDAT"
        if tag == b"IEND":
            return saw_data
        offset = end
    return False


def delimiters_valid(source):
    """Static lexical sanity check (not a GDScript parser)."""
    stack = []
    i = 0
    string_type = None
    triple = False
    comment = False
    pairs = {')': '(', ']': '[', '}': '{'}
    while i < len(source):
        ch = source[i]
        if comment:
            if ch == '\n':
                comment = False
            i += 1
            continue
        if string_type:
            if ch == '\\':
                i += 2
                continue
            if triple and source.startswith(string_type * 3, i):
                i += 3
                string_type = None
                continue
            if not triple and ch == string_type:
                string_type = None
            i += 1
            continue
        if ch == '#':
            comment = True
        elif ch in ('"', "'"):
            string_type = ch
            triple = source.startswith(ch * 3, i)
            if triple:
                i += 3
                continue
        elif ch in '([{':
            stack.append(ch)
        elif ch in ')]}':
            if not stack or stack.pop() != pairs[ch]:
                return False
        i += 1
    return not stack and not string_type


project = read('project.godot')
farm = read('scripts/NativeFarm.gd')
boot = read('scripts/Boot.gd')
main = read('scripts/Main.gd')
compass = read('scripts/FarmCompass.gd')
nav = read('scripts/BeautifulFarm.gd')
runner_sh = read('RUN_NATIVE_TESTS.sh')
runner_bat = read('RUN_NATIVE_TESTS.bat')

check('6.0 version in project, launcher, and gameplay HUD', all('6.0' in s for s in [project, boot, main]))
check('Native Godot 4.4+ startup files retained', all((ROOT / n).is_file() for n in ['project.godot','Boot.tscn','Main.tscn']))
check('PC/tablet/mobile responsive layout retained', all(x in main for x in ['ResponsiveLayout.gd','_create_mobile_nav55','_sync_mobile_panels55','MarginContainer.new()']))
check('2D and 2.5D modes retained', 'IsoWorld56.new() if use_25d else WorldScript.new()' in main)
check('Farm Compass pure advisory module exists', 'extends RefCounted' in compass and 'func priorities(' in compass and 'func pillars(' in compass)
check('Farm Compass recommendations are read-only', all(not re.search(r'\bfarm\.(?:act|save_file|new_game|load_file)\s*\(', compass) for _ in [0]))
check('Six cross-system milestone paths', all(f'"id":"{n}"' in compass for n in ['land','harvest','animals','production','community','exploration']))
check('Priorities include harvest, water, pests, welfare, storage and planting', all(f'"id":"{n}"' in compass for n in ['harvest','water','pests','animals','storage','plant']))
check('Compass screen and jump action wired to live world state', all(x in main for x in ['"Compass60": _panel_compass60()','func _jump_compass60','world.set_selected(field_id)','func _panel_compass60']))
check('Quick recommendations appear on the farm overview', all(x in main for x in ['Compass60.priorities(farm,language)','Your next steps','_jump_compass60.bind(task60)']))
check('Compass accessible in mobile and desktop navigation', main.count('"Compass60",tx("Goals","Metas")') >= 2)
check('Compass accessible in screen picker', '"Compass60"' in nav)
check('Legacy 5.9 and isolated 6.0 autosave paths', 'fieldwork_native_6_0.json' in farm and 'fieldwork_native_5_9.json' in farm and 'V59_SAVE_FILE' in boot)
check('Legacy 5.9 and isolated 6.0 save-slot directories', 'fieldwork_slots_60' in farm and 'V59_SLOT_DIRECTORY' in farm and 'fieldwork_slots_59' in farm)
check('5.9 primary and backup import paths reachable', 'V59_SAVE_FILE + ".bak2"' in farm and 'V59_SAVE_FILE + ".bak"' in farm)
check('5.9 manual-slot imports in both info and loading functions', farm.count('v59 + ".bak2"') == 2 and farm.count('var v59: String') == 2)
check('Existing schema/checksum format preserved', 'const VERSION = 10' in farm and 'FW_NATIVE_5_4' in farm)
check('Engine smoke test included in both runners', all('complete_experience_smoke' in x for x in [runner_bat,runner_sh]))
check('Engine smoke verifies 5.9 imports, immutable advisory and UI', all(x in read('tests/complete_experience_smoke.gd') for x in ['Farm.V59_SAVE_FILE','farm.export_text() == before','_change_tab","Compass60"']))

sources = list((ROOT/'scripts').glob('*.gd')) + list((ROOT/'tests').glob('*.gd'))
source_leaks = []
for p in sources + list(ROOT.glob('*.tscn')):
    for match in re.finditer(r'(?:preload|load)\s*\(\s*"res://([^"\n]+)"|path="res://([^"\n]+)"',p.read_text(encoding='utf-8')):
        target = match.group(1) or match.group(2)
        if not (ROOT/target).is_file():
            source_leaks.append(f'{p.relative_to(ROOT)} -> {target}')
check('All literal resource imports and scene paths exist', not source_leaks)
collisions = []
for p in (ROOT/'scripts').glob('*.gd'):
    source = p.read_text(encoding='utf-8')
    funcs = re.findall(r'^(?:static\s+)?func\s+(\w+)\(',source,re.M)
    var_names = re.findall(r'^var\s+(\w+)\b',source,re.M)
    sig_names = re.findall(r'^signal\s+(\w+)\b',source,re.M)
    if len(set(funcs)) != len(funcs) or set(var_names).intersection(sig_names):
        collisions.append(str(p.relative_to(ROOT)))
check('No repeated function definitions or signal/property collisions',not collisions)
lex = [str(p.relative_to(ROOT)) for p in sources if not delimiters_valid(p.read_text(encoding='utf-8'))]
check('GDScript lexical delimiter/string scan passes',not lex)
files = list((ROOT/'assets').rglob('*.png'))
check('All project PNG assets have valid PNG signatures and CRC',len(files)>220 and all(image_ok(p) for p in files))
check('All project JSON data parse',all(isinstance(json.loads(p.read_text(encoding='utf-8')),dict) for p in (ROOT/'data').glob('*.json')))
baseline = json.loads(read('tests/BASELINE_59_ART_DATA_SHA256.json'))
changed = [name for name,old in baseline.items() if not (ROOT/name).is_file() or hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=old]
check('All inherited 5.9 artwork/data unchanged',len(baseline)>220 and not changed)
check('6.0 documentation and tests included',all((ROOT/n).is_file() for n in ['README.md','CHANGELOG.md','docs/ARCHITECTURE.md','docs/COMPLETE_FARMING_6_0.md','tests/complete_experience_smoke.gd']))
check('README documents engine execution limitation','not runtime-verified' in read('README.md'))
failed = [title for title,ok in results if not ok]
report = {'release':'Fieldwork 6.0 - Complete Farming Experience','checks':len(results),'passed':len(results)-len(failed),'failed':failed,'godot_engine_executed':False,'missing_resources':source_leaks,'script_collisions':collisions,'lexical_failures':lex,'modified_inherited_art_or_data':changed}
(ROOT/'tests/QA_RESULT.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(f"6.0 OFFLINE QA: {report['passed']}/{report['checks']} passed")
sys.exit(1 if failed else 0)
