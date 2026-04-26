---
name: agente-constructor
description: Construye lobby, dimensiones y elementos del juego Choose Doors (Elegir Puertas) en Roblox Studio vía MCP. Aplica arquitectura realista, reglas anti-Z-fighting, coherencia material y respeta los sistemas pre-existentes (QueueManager, GameManager, MatchQueues). Skill autocontenida con todo el contexto del proyecto.
---

El usuario quiere construir algo en Roblox Studio para el proyecto **Choose Doors / Elegir Puertas**: $ARGUMENTS

Esta skill es **autocontenida** — no invocar otras skills de construcción. Usa el mismo helper MCP que el resto del kit (`roblox-mcp.ps1`) y reúne aquí todo el contexto del juego, reglas de construcción profesional y especificaciones de cada espacio.

---

## CÓMO HABLAR CON STUDIO

Mismo patrón que `/roblox` y `/roblox-script`:

```powershell
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "TOOL_NAME" -Args 'JSON_ARGS' -AutoStart
```

`-AutoStart` arranca el servidor si está caído. `-SaveLarge` guarda respuestas grandes a archivo.

Si el helper no existe, fallback inline:

```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
$body = '{"jsonrpc":"2.0","method":"tools/call","id":1,"params":{"name":"TOOL","arguments":ARGS_JSON}}'
$r = Invoke-RestMethod -Uri "http://localhost:58741/mcp" -Method POST -Body $body -ContentType "application/json" -Headers @{"Accept"="application/json, text/event-stream"}
$json = ($r -split "`n" | Where-Object { $_ -match '^data: ' } | Select-Object -First 1) -replace '^data: ', ''
($json | ConvertFrom-Json).result.content | ForEach-Object { $_.text }
```

Si el servidor no responde o el plugin no está conectado, indicar al usuario que corra `/roblox-status` y `/roblox-start`. No diagnosticar aquí.

---

## TOOL DE PREFERENCIA POR OPERACIÓN

| Quiero... | Tool MCP | Cuándo |
|---|---|---|
| Crear muchas partes en una llamada | `mass_create_objects` | **Default para construcción.** Cientos de partes en un solo round-trip, queda en el historial de undo. |
| Crear 1 parte | `create_object` | Casos sueltos. |
| Setear varias propiedades de una parte | `set_properties` | Después de crear con valores especiales. |
| Setear la misma propiedad en muchas partes | `mass_set_property` | Material, transparencia, color en bloque. |
| Duplicar con offset/variación | `smart_duplicate` | Filas de columnas, sillas, antorchas equiespaciadas. |
| Cambiar Lighting / SoundService / lógica computada | `execute_luau` | Solo cuando no hay tool dedicado. **No queda en undo.** |
| Capturar el resultado | `capture_screenshot` | Después de cada parte construida. |
| Verificar qué hay antes de tocar | `get_instance_children`, `search_objects` | **Siempre antes de destruir o sobrescribir.** |

**Regla:** prefiere `mass_create_objects` por encima de scripts Luau largos. Un `execute_luau` de 150 líneas con un loop que crea partes es más lento, no se puede deshacer, y tiene riesgo de timeout. La única razón válida para `execute_luau` aquí es: cálculos (bounding boxes, posiciones derivadas), tweens en runtime, configuración de servicios (Lighting, SoundService), o lógica que no expresa el catálogo de tools.

---

## CONTEXTO DEL PROYECTO

### Qué es Choose Doors / Elegir Puertas
Juego de supervivencia horror estilo Doors. Los jugadores eligen entre N puertas, cada una los lleva a una dimensión peligrosa donde sobreviven 30 segundos contra una entidad. 100 puertas en total, 10 dimensiones distintas, 3 bosses.

### Modos
- **Campaña:** cooperativo 1-4 jugadores, 100 puertas en secuencia, checkpoints en 1/26/51.
- **Multijugador:** competitivo hasta 10 jugadores, 3 rondas, último en pie gana.

### Fases de puertas
| Fase | Puertas | Cantidad de elección | Mutaciones |
|---|---|---|---|
| Aprendizaje | 1-25 | 2 puertas | 0 |
| Mutación | 26-50 | 3 puertas | 1 |
| Combinación | 51-98 | 4 puertas | 3 |
| Gauntlet | 99 | 10 puertas | 3 |
| Boss final | 100 | 1 puerta | 0 |

---

## SISTEMAS PRE-EXISTENTES (no romper)

El proyecto tiene scripts que **viven solo en el `.rbxl`** (no en `src/`). Antes de destruir cualquier parte de `Workspace`, verificar qué espera el código existente con `get_descendants` o `grep_scripts`.

**ServerScriptService:**
- `GameManager` — flujo de campaña, dispara `Remotes.RequestStartCampaign`.
- `QueueManager` — espera `Workspace:WaitForChild("Lobby")` con `MatchQueues > Queues`.
- `PlayerDataManager` — DataStore de progreso.
- `ResurrectionShop` — tienda.

**StarterPlayer.StarterPlayerScripts:**
- `FirstPersonLock`, `ClientGameHandler`, `LeaveButtonClient`.

**Reglas inviolables:**
- El folder principal del lobby **debe llamarse `Lobby`** (no `CastleLobby`). `QueueManager` lo busca por ese nombre.
- Preservar `Workspace.Lobby.MatchQueues.Queues` con sus children al reconstruir.
- Shape de cada queue: `Display` (BasePart con `BillboardGui` → `CountLabel`), `TeleportSpot`, `LeaveSpot`, `DetectionRing`, `DetectionZone`.

Antes de demoler, **mover `MatchQueues` a un parent temporal** (ej. `ServerStorage._SafeKeeping`) con `move_object`, reconstruir, y luego restaurarlo.

---

## REGLAS ANTI-Z-FIGHTING (CRÍTICAS)

Z-fighting es cuando dos superficies en la misma posición Y parpadean. Evítalo:

### Losetas de piso
```
NUNCA dos losetas en la misma posición (X, Y, Z).
NUNCA dos losetas con la misma coordenada Y si se solapan en X y Z.
```

```lua
-- CORRECTO: cada loseta tiene posición única
for col = 0, numCols - 1 do
    for row = 0, numRows - 1 do
        local x = startX + col * tileSize + tileSize/2
        local z = startZ + row * tileSize + tileSize/2
        local size = Vector3.new(tileSize - 0.1, 0.5, tileSize - 0.1)
    end
end
-- INCORRECTO: piso base sólido + losetas encima → Z-fighting
```

### Paredes dobles
```
NUNCA dos paredes en el mismo plano.
Paneles decorativos ADELANTE de la pared por al menos 0.15 studs.
```

### Piso base vs losetas
Elige UNO: o piso base sólido, o losetas. NO ambos.

### Superposición vertical
Antes de colocar una parte, verificar que ninguna otra ya ocupe ese espacio:
```
parteA Y rango: [posA.Y - sizeA.Y/2, posA.Y + sizeA.Y/2]
parteB Y rango: [posB.Y - sizeB.Y/2, posB.Y + sizeB.Y/2]
Si Y se solapa Y X se solapa Y Z se solapa → Z-FIGHTING.
```

---

## COHERENCIA ARQUITECTÓNICA

### Cadena de carga vertical (todo apoya en algo)
```lua
local FT = 0.5  -- Floor Top
-- Base de columna se PARA en el piso
local BASE_Y = FT + BASE_H/2
-- Shaft se PARA en la base
local SHAFT_Y = BASE_Y + BASE_H/2 + SHAFT_H/2
-- Capital se PARA en el shaft
local CAP_Y = SHAFT_Y + SHAFT_H/2 + CAP_H/2
-- NUNCA usar Y absoluto. SIEMPRE encadenar.
```

### Materiales por función (nunca al revés)

| Función | Materiales correctos | NUNCA usar |
|---|---|---|
| Carga (columnas, muros) | Granite, Concrete, Brick, Slate | Plastic, SmoothPlastic, Wood |
| Vigas de techo | WoodPlanks, Wood, Metal | Marble, Glass |
| Pisos | Marble, Slate, Cobblestone, WoodPlanks | Fabric, Neon |
| Trim/molduras | Granite oscuro, Metal, Wood | Glass |
| Telas (tapices, mantel) | Fabric | Plastic |
| Fuego, vitrales | Neon + Transparency 0.2-0.5 | SmoothPlastic |
| Metal (cadenas, antorcha) | Metal | Wood |

### Juntas
Donde dos partes se tocan: overlap de 0.1-0.2 studs + trim que cubra la unión + materiales diferentes para distinguir visualmente.

### Escala humana (personaje Roblox ~5 studs)
- Puertas: 6-8 ancho × 10-12 alto
- Columnas: 16-40 alto × 2-3 ancho
- Pasillos: 10-14 ancho
- Habitaciones íntimas: 40-80 ancho
- Salones grandes: 100-320 ancho
- Antorchas: 5-7 alto (sobre la cabeza)
- Techos: 14-20 (íntimo) a 40-60 (catedralicio)

### Asimetría
No hagas todo perfectamente simétrico — molduras irregulares, alfombras desplazadas, antorchas no equidistantes (variar ±2 studs). Lo simétrico se siente artificial.

---

## LIGHTING POR ESPACIO

Lighting siempre se aplica con `execute_luau` (no hay tool dedicado para servicios). **`Lighting.Technology` no se setea desde plugin context** — envolver en `pcall(function() Lighting.Technology = Enum.Technology.Future end)`.

### Lobby (cálido, diurno, contraste con horror)
```lua
Lighting.ClockTime = 14.5
Lighting.Ambient = Color3.fromRGB(100, 85, 65)
Lighting.OutdoorAmbient = Color3.fromRGB(190, 158, 115)
Lighting.Brightness = 2.2
-- Atmosphere: Density 0.18-0.22, Color (225,205,175), Glare 0.5
-- Bloom: Intensity 0.5-0.6, Threshold 1.5
-- ColorCorrection: Tint (255,240,215), Contrast 0.12
-- SunRays: Intensity 0.18-0.22
```

### Horror (D1, D3, D7, D8, etc.)
```lua
pcall(function() Lighting.Technology = Enum.Technology.Future end)
Lighting.Ambient = Color3.fromRGB(20, 18, 25)
Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 15)
Lighting.ClockTime = 0
Lighting.GlobalShadows = true
-- Atmosphere: Density 0.3-0.4, Haze 2-4
-- Bloom: Intensity 0.4-0.6, Threshold 1.5-2
-- ColorCorrection: Contrast 0.15, Saturation -0.2
```

---

## HELPERS LUAU (solo dentro de execute_luau)

Cuando uses `execute_luau` para colocar partes que requieren cálculo derivado, incluye estos helpers al inicio del script:

```lua
local function mp(parent, props)
    local p = Instance.new("Part")
    for k, v in pairs(props) do p[k] = v end
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function addLight(parent, lightType, color, brightness, range)
    local l = Instance.new(lightType or "PointLight")
    l.Color = color
    l.Brightness = brightness or 2
    l.Range = range or 16
    l.Shadows = true
    l.Parent = parent
    return l
end

local function safeSet(obj, prop, val)
    return pcall(function() obj[prop] = val end)
end
```

Para volúmenes grandes de partes sin cálculo derivado, **usa `mass_create_objects` directamente** y ahorra el `execute_luau`.

### Ejemplo: piso de losetas con `mass_create_objects`
```powershell
$objects = @()
for ($col = 0; $col -lt 32; $col++) {
    for ($row = 0; $row -lt 18; $row++) {
        $objects += @{
            className = "Part"
            parent    = "game.Workspace.Lobby.Floor"
            name      = "Tile_${col}_${row}"
            properties = @{
                Anchored = $true
                Material = "Marble"
                Size     = @{ X = 9.9; Y = 0.5; Z = 9.9 }
                Position = @{ X = -160 + $col*10 + 5; Y = 0.25; Z = -90 + $row*10 + 5 }
            }
        }
    }
}
$argsJson = @{ objects = $objects } | ConvertTo-Json -Depth 10 -Compress
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "mass_create_objects" -Args $argsJson
```

---

## ESPECIFICACIÓN: LOBBY PRINCIPAL

### Estética
- **Castillo medieval realista, NO horror.** Luz cálida diurna por ventanas grandes. Elegante, no opresivo.
- Paleta: piedra beige cálida, madera oscura nogal, alfombra granate, dorado/bronce, vitrales con paneles rojo/azul/ámbar/verde.

### Dimensiones
- **320 × 180 × 60 studs** (4× área del lobby base anterior).
- Origen centrado en (0,0,0). `SpawnLocation` cerca del muro de entrada (-L/2 + ~30).
- Folder raíz: `Workspace.Lobby` (NO `CastleLobby` — `QueueManager` se cuelga).

### Realismo arquitectónico
- **Vitrales** con grid 4×6 paneles alternando colores (rojo rubí, azul cobalto, ámbar, verde esmeralda, violeta, crema), mullions de bronce, arco superior + sill bottom de granito.
- **Columnas góticas:** base escalonada 3 niveles + fuste de mármol + capital ornado de granito.
- **Pilastras** en muros back/front (medias columnas decorativas).
- **Cofres en el techo:** vigas transversales cada ~30 studs + paneles oscuros recessed entre vigas + roseta central de bronce.
- **Sconces** entre cada par de ventanas (backplate + brazo + copa + llama neón con `PointLight`).
- **Chandeliers:** 8 grandes (anillo de 12 velas + anillo interior de 6) + 4 centrales pequeños sobre la alfombra.
- **Alfombra principal** con cenefa de rombos + bordes dorado y azul real + alfombra adicional frente a la chimenea.
- **Chimenea masiva** (30 ancho × 28 alto): postes laterales de granito, lintel, mantel con candelabros y reloj central, escudo heráldico arriba, hearth, andirons, troncos, fuego en 3 capas neón.
- **Trono en tarima de 3 escalones**, respaldo de 16 studs, brazos tallados, corona de bronce, 2 columnas decorativas a los lados, 2 antorchas-pie altas.
- **Mesa de banquete** 70 studs largo, mantel + runner granate, 5 candelabros centrales (3 brazos cada uno), 12 platos+goblets, 12 sillas tapizadas en granate.
- **Tapices** entre pares de columnas con escudos heráldicos en 4 paletas (granate/dorado, azul/dorado, granate/azul, verde/dorado).
- **Armaduras completas** (6) sobre pedestales con casco+plumacho, lanza, escudo emblemado.
- **Librerías** altas (26 studs) a los lados de la chimenea + en muro frontal, con libros de colores variados.
- **Estatuas** (4) de mármol con halo dorado en pedestales.
- **Banners colgantes** del techo con escudo central.

### Funcionalidad
- `SpawnLocation` neutral sobre alfombrilla dorada cerca del muro de entrada.
- **Área frontal** (extremo del trono) reservada para puertas a elegir — déjala despejada salvo trono y candelabros.
- **Preservar `Lobby.MatchQueues.Queues`** con sus children al reconstruir. Si construyes desde cero, mover `MatchQueues` a `ServerStorage._SafeKeeping` con `move_object` y restaurarlo después.
- Estructura jerárquica del folder: `Floor`, `Walls`, `Ceiling`, `Windows`, `Columns`, `Buttresses`, `Sconces`, `Chandeliers`, `Decor`, `Fireplace`, `ThroneArea`, `BanquetTable`, `Tapestries`, `Armors`, `Bookshelves`, `Statues`, `Banners`, `Spawn`.

### Música ambiental
- Crear `Sound` en `SoundService` llamado `LobbyMusic`: `Volume=0.3`, `Looped=true`, `RollOffMode=Linear`.
- **NO asumir un `SoundId` pre-existente.** Roblox modera audio comunitario; los IDs comunes para "Fallen Down" suelen no ser audio (devuelven *"Asset type does not match"*).
- Dejar `SoundId=""`, `Playing=false`, atributo `PendingUserUpload=true`.
- Instruir al usuario a subir su propio audio desde Toolbox → Audio o desde [https://create.roblox.com/dashboard/creations/audio](https://create.roblox.com/dashboard/creations/audio).

---

## ESPECIFICACIÓN: DIMENSIONES (D1–D10)

### D1 — Los Backrooms (Nivel 0)
- Pasillos amarillos infinitos, alfombra húmeda, luces fluorescentes parpadeantes.
- `ClockTime` 12, `Ambient` amarillo (150,130,60), niebla densa amarilla.
- Material muros: `SmoothPlastic` amarillo-mostaza; piso: `Fabric` (alfombra amarilla); techo: panels blanco-amarillento con luces fluorescentes (`Neon` blanco).
- Layout: laberinto generado, ~20 cuartos cuadrados conectados, sin ventanas, sin techos definidos.

### D2 — La piscina liminal
- Piscinas interconectadas, azulejos blancos, agua turquesa, eco.
- Material muros/piso: `Marble` blanco; agua: Terrain water o Part `Neon` turquesa con `Transparency` 0.4.
- Iluminación: `ClockTime` 6 (amanecer), ambient neutro, reflejos en agua.

### D3 — Hospital abandonado
- Pasillos decadentes, manchas en paredes, oscuridad.
- `ClockTime` 3, `Ambient` (40,40,50), niebla corta.
- Material: ladrillo manchado, baldosas rotas (`Slate` gris), camillas de `Metal` oxidado, luces fluorescentes parpadeantes.

### D4 — Catacumbas sin fin
- Laberinto de túneles de piedra, oscuridad total, linterna obligatoria.
- `ClockTime` 0, `Ambient` (5,5,8), `GlobalShadows` true, sin `OutdoorAmbient`.
- Material muros/techo: `Slate` piedra oscura; piso: `Cobblestone` con polvo; antorchas apagadas (decoración).

### D5 — Centro comercial 3AM (maniquíes)
- Mall vacío de noche, tiendas cerradas, luces intermitentes.
- `ClockTime` 22, `Ambient` (30,30,35), luces fluorescentes esporádicas.
- Material: piso de `Marble` crema, muros `SmoothPlastic` claro, vitrinas de `Glass`.

### D6 — Estación de tren abandonada
- Estación subterránea, vías oxidadas, trenes fantasma.
- `ClockTime` 1, `Ambient` (25,30,38), niebla baja.
- Material: `Concrete` muros, `Metal` oxidado vías, baldosas `Slate`.

### D7 — Bosque de la niebla
- Bosque denso de noche, niebla espesa, árboles retorcidos.
- `ClockTime` 22, `Ambient` (15,20,25), niebla muy corta.
- Material: `Wood` troncos retorcidos, suelo `Grass` oscuro/`Mud`.

### D8 — Estacionamiento infinito
- Parking subterráneo concreto, pisos descendentes.
- `ClockTime` 0, `Ambient` (35,35,40), luces fluorescentes verdosas.
- Material: `Concrete` todo, columnas grises, líneas amarillas.

### D9 — Biblioteca prohibida
- Estantes gigantes, ambiente silencioso, distorsión visual.
- `ClockTime` 18 (atardecer rojizo), `Ambient` (60,40,30), polvo en aire.
- Material: `WoodPlanks` oscura para estantes, libros `Fabric` variados, piso `Marble` manchado.

### D10 — Cuarto que encoge
- Cuarto blanco que se reduce.
- `ClockTime` 12, `Ambient` blanco, luz uniforme cegadora.
- Material: `SmoothPlastic` blanco puro todo.
- Mecánica: `TweenService` para mover paredes hacia el centro.

---

## CHECKLIST ANTES DE GENERAR CÓDIGO

1. ☐ ¿Cada parte apoya en algo debajo? (no flota)
2. ☐ ¿Ninguna loseta se solapa con otra? (no Z-fighting)
3. ☐ ¿No hay piso base + losetas encima? (uno u otro)
4. ☐ ¿Materiales coinciden con su función?
5. ☐ ¿Juntas con overlap 0.1-0.2?
6. ☐ ¿Posiciones Y encadenadas (no absolutas)?
7. ☐ ¿Variedad de materiales (mínimo 3)?
8. ☐ ¿Lighting con `Future` + `Atmosphere` + `Bloom`?
9. ☐ ¿Escala humana respetada?
10. ☐ ¿Asimetría intencional para realismo?
11. ☐ ¿Folder con nombre correcto (`Lobby` para el lobby principal)?
12. ☐ ¿`MatchQueues.Queues` preservado si reconstruyo?
13. ☐ ¿Estoy usando `mass_create_objects` en vez de un `execute_luau` largo?

---

## FLUJO DE EJECUCIÓN

1. **Inspeccionar** el estado actual antes de tocar nada:
   - `get_instance_children {"instancePath":"game.Workspace"}`
   - `search_objects {"query":"MatchQueues"}` para confirmar que existe.
   - `get_descendants {"instancePath":"game.Workspace.Lobby","maxDepth":2}` si reconstruyes.
2. **Planificar** en partes (rastrearlas con `TodoWrite`). Una parte = un folder o subsistema (Floor, Walls, Ceiling, Sconces, Chandeliers, Fireplace, etc.). Mantén cada llamada de `mass_create_objects` por debajo de ~500 partes.
3. **Salvaguardar** sistemas pre-existentes:
   - `move_object {"instancePath":"game.Workspace.Lobby.MatchQueues","targetParentPath":"game.ServerStorage"}` antes de demoler.
4. **Construir** parte por parte:
   - Default: `mass_create_objects`.
   - Solo `execute_luau` para Lighting, SoundService, posiciones derivadas o tweens.
5. **Restaurar** lo salvaguardado:
   - `move_object` de vuelta a `game.Workspace.Lobby`.
6. **Validar** después de cada parte: `capture_screenshot` desde un par de ángulos.
7. **Reportar** al usuario con el formato estándar de abajo.

Si una llamada falla con timeout o error de conexión, detente y pide al usuario `/roblox-status`.

---

## OUTPUT ESPERADO AL USUARIO

Después de cada construcción exitosa, reportar:

> **Construido:** `Workspace.Lobby` con N partes en M folders.
>
> **Estructura creada:**
> - `Floor` (X partes), `Walls` (Y), `Ceiling` (Z), ...
>
> **Sistemas preservados:** `MatchQueues.Queues` con sus children intactos.
>
> **Acciones manuales pendientes** (si aplica):
> - Subir audio para `SoundService.LobbyMusic.SoundId` desde [create.roblox.com/dashboard/creations/audio](https://create.roblox.com/dashboard/creations/audio).
> - Crear queues nuevas dentro de `Lobby.MatchQueues.Queues` con el shape estándar.
>
> **Screenshots:** [vista panorámica], [trono], [chimenea].
>
> **¿Algún ajuste?** [opciones específicas: paleta, escala, decoración].
