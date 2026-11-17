# Fieldwork 3D: notas técnicas

## Arquitectura

`NativeFarm.gd` sigue siendo la autoridad de las transacciones y del estado guardado. Los renderizadores solo consultan este estado y emiten señales para que `Main.gd` ejecute las acciones existentes.

| Archivo | Responsabilidad |
|---|---|
| `scripts/three_d/Models.gd` | Mallas y materiales compartidos; modelos originales y geometría de cultivos |
| `Viewport3D.gd` | SubViewport independiente, cámara, rayos, gestos y calidad |
| `FarmView3D.gd` | Coordenadas originales 64×54, parcelas, estado visual, entidades y selección |
| `ValleyView3D.gd` / `Regions.gd` | Maqueta del valle y destinos originales |
| `InteriorView3D.gd` | Habitaciones abiertas y objetos interactivos |
| `PortraitView3D.gd` | Previsualización del mismo agricultor utilizado en el mundo |
| `MachinePreview3D.gd` | Modelos en el catálogo de maquinaria |
| `Backdrop3D.gd` | Finca privada de muestra para menús, sin acceso a partidas |
| `GameTheme.gd` | Fuentes, colores y estilos comunes |
| `water.gdshader` | Agua con ondulación; se detiene con movimiento reducido |

Se han eliminado los seis renderizadores 2D/2.5D sustituidos. Los PNG heredados permanecen disponibles como recursos de origen, pero no se utilizan para representar el mundo, los interiores ni el personaje.

Los cultivos tienen siluetas por familia y especie, con fases de crecimiento diferenciadas: cereales y maíz, raíces, hojas, flores, frutos, vides y árboles. El viento mueve sutilmente las partes altas. Los animales tienen formas y detalles propios de cada especie, variación determinista entre individuos y movimiento idle; los edificios de producción incorporan detalles acordes a su uso. Se conserva el estilo low-poly, sin personajes de alta resolución ni materiales fotorealistas.

## Correcciones del código original

- `JSON.parse_string` produce valores `float`. Las comprobaciones estrictas `is int` del validador impedían volver a cargar partidas válidas. `NativeData.is_json_integer` acepta valores numéricos integrales finitos, conserva los límites existentes y rechaza fracciones, cadenas y booleanos. Se aplica también al progreso regional.
- Se sustituye la llamada inexistente `base.get_child_index(center_row)` por `center_row.get_index()` al reorganizar una ventana pequeña.
- Los valores del HUD dejan de perder su ancho mínimo dentro de un contenedor de flujo.
- Se evita que las acciones contextuales formen una columna y resten altura al mundo.

## Resultado verificado

**Godot 4.6.2 en Windows:** `tests/smoke.gd`, 408 comprobaciones; `tests/campaign.gd`, 42 comprobaciones; 0 fallos en ambas. Las capturas de escenas reales se generaron y revisaron previamente con Godot 4.6.3 en Linux.

## Pruebas reproducibles

Ejecutar desde la raíz del proyecto. Es importante aislar los datos: la prueba de integración escribe deliberadamente archivos de guardado para verificar recuperación y continuación.

```bash
mkdir -p /tmp/fieldwork-test/data /tmp/fieldwork-test/config /tmp/fieldwork-test/cache
export XDG_DATA_HOME=/tmp/fieldwork-test/data
export XDG_CONFIG_HOME=/tmp/fieldwork-test/config
export XDG_CACHE_HOME=/tmp/fieldwork-test/cache
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/campaign.gd
```

Para capturar las escenas reales hace falta un servidor gráfico y OpenGL 3.3:

```bash
godot --audio-driver Dummy --path . --script tests/capture.gd -- all /tmp/fieldwork-previews
```

Las capturas `farm`, `detail`, `valley`, `interior`, `portrait` y `phone` usan una partida de prueba poblada; `new` muestra el inicio real con una sola parcela. La finca del menú es una composición de muestra. Ninguna de estas capturas guarda la partida de muestra.

La integración comprueba transacciones, invariantes, guardado y carga, determinismo tras cargar, prioridades diarias de agua, nutrientes, plagas, enfermedades y contratos, 24 colisiones de parcelas, capas, calidad, catálogo de modelos, todas las pantallas en inglés y español, apertura y cierre de ventanas, vistas ocultas y tamaños de 440×800, 960×640 y 1440×900.

`tests/campaign.gd` ejecuta la campaña de Historia con acciones reales de cultivo, venta, expansión, construcción, formación y contratos. También resuelve los eventos generados y guarda/reanuda la partida durante la campaña y al finalizar. La campaña contiene tres capítulos y un epílogo visible en el panel de Historia; los objetivos finales son completar tres edificios y alcanzar 10 puntos de reputación. Al completarla, la finca permanece abierta para seguir jugando. Con la semilla incluida completó en el día 34, con 2973,6 kg cosechados, un contrato entregado y 15 eventos resueltos. Esta prueba cubre la simulación nativa, no la interacción manual ni todos los dispositivos o semillas.

Entorno verificado para las capturas: Godot 4.6.3, Linux, Compatibility/OpenGL y Mesa llvmpipe por software. La resolución reducida y las sombras cambian la carga gráfica, pero no se ha medido rendimiento en hardware del usuario. Android, iOS, mandos, multitáctil físico y exportaciones de escritorio requieren pruebas en sus dispositivos.
