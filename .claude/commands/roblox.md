---
name: roblox
description: Interactúa con Roblox Studio en tiempo real vía MCP. Lee/escribe instancias, ejecuta Luau, edita scripts, crea objetos, toma screenshots, corre playtests. Auto-arranca el servidor si está caído.
---

El usuario quiere interactuar con Roblox Studio: $ARGUMENTS

## Cómo llamar tools (helper recomendado)

```powershell
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "TOOL_NAME" -Args 'JSON_ARGS' -AutoStart
```

`-AutoStart` arranca el servidor automáticamente si está caído. `-SaveLarge` guarda respuestas grandes a un archivo temporal.

Si el helper no existe (proyecto compartido sin instalar), usa el patrón inline:

```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
$body = '{"jsonrpc":"2.0","method":"tools/call","id":1,"params":{"name":"TOOL","arguments":ARGS_JSON}}'
$r = Invoke-RestMethod -Uri "http://localhost:58741/mcp" -Method POST -Body $body -ContentType "application/json" -Headers @{"Accept"="application/json, text/event-stream"}
$json = ($r -split "`n" | Where-Object { $_ -match '^data: ' } | Select-Object -First 1) -replace '^data: ', ''
($json | ConvertFrom-Json).result.content | ForEach-Object { $_.text }
```

## Selección de tool

### Quiere explorar?
- "qué hay en X" / "muéstrame Y" → `get_instance_children` o `get_descendants`
- "encuentra X" → `search_objects`
- "qué tiene seleccionado" → `get_selection`
- "info del juego" → `get_place_info`

### Quiere leer/editar scripts?
- "muéstrame el script X" → `get_script_source`
- "busca 'foo' en los scripts" → `grep_scripts`
- "cambia 'foo' por 'bar' en X" → `edit_script_lines` (NO `set_script_source` para cambios pequeños)
- "reescribe X completo" → `set_script_source`
- "reemplaza globalmente foo por bar" → `find_and_replace_in_scripts {"dryRun": true}` primero
- "verifica errores de sintaxis" → `get_script_analysis`

### Quiere crear/modificar?
- "crea un Part" → `create_object`
- "crea una UI" → `create_ui_tree`
- "crea N objetos" → `mass_create_objects`
- "duplica X N veces" → `smart_duplicate`
- "cambia la propiedad" → `set_property` (1) o `set_properties` (varias)
- "borra X" → `delete_object` (CONFIRMAR primero)

### Quiere ejecutar Luau?
- `execute_luau` — pero solo si no hay tool dedicado

### Quiere debuggear?
- "corre el juego" → `start_playtest {"mode": "play"}`
- "qué dice la consola" → `get_output_log`
- "captura pantalla" → `capture_screenshot`

## Reglas

1. **Antes de modificar, verifica que el path existe** — `search_objects` o `get_instance_children`
2. **Usa `FindFirstChild` en Luau**, no acceso por punto directo
3. **`ScaleTo` es absoluto** — para multiplicar: `model:ScaleTo(model:GetScale() * factor)`
4. **No uses `undo`/`redo`** después de `execute_luau` — bypassea historial
5. **Confirma borrados** y modificaciones masivas antes de ejecutar
6. **En proyectos Rojo** (con `default.project.json`), edita scripts vía Read/Edit en el filesystem cuando sea posible — son las fuentes de verdad

## Output

Presenta resultados como:
- Tablas markdown para listas
- Bloques de código para Luau
- Texto plano formateado para info de instancias
- NO muestres JSON crudo si puedes evitarlo

## Ejecución

Ejecuta el PowerShell, parsea el resultado, presenta de forma útil. Para tareas multi-paso, encadena llamadas (ej: explorar → confirmar → modificar).
