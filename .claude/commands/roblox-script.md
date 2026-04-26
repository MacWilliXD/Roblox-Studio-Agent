---
name: roblox-script
description: Operaciones enfocadas en scripts. Lee, edita, busca y analiza scripts en Studio vía MCP.
---

El usuario quiere trabajar con scripts: $ARGUMENTS

Los scripts viven en Studio (DataModel) y se editan vía las tools del MCP. No asumas filesystem-as-source-of-truth.

## Operaciones

### Listar todos los scripts del juego
```powershell
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "get_project_structure" -Args '{"maxDepth":5,"scriptsOnly":true}'
```

### Leer un script
```powershell
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "get_script_source" -Args '{"instancePath":"game.ServerScriptService.MyScript"}'
```

### Buscar texto en todos los scripts (tipo ripgrep)
```powershell
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "grep_scripts" -Args '{"pattern":"foo","caseSensitive":false,"contextLines":2,"maxResults":50}'
```
Filtros útiles:
- `"path":"game.ServerScriptService"` — limitar a una rama
- `"classFilter":"LocalScript"` — solo cliente
- `"usePattern":true` — Lua pattern matching

### Edición quirúrgica (PREFERIDO para cambios pequeños)
```powershell
$args = @{
    instancePath = "game.ServerScriptService.MyScript"
    old_string = "local x = 5"
    new_string = "local x = 10"
} | ConvertTo-Json -Compress
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "edit_script_lines" -Args $args
```

### Reescribir script completo (solo si tiene sentido)
```powershell
$args = @{
    instancePath = "game.ServerScriptService.MyScript"
    source = "-- nuevo contenido completo`nprint('hello')"
} | ConvertTo-Json -Compress
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "set_script_source" -Args $args
```

### Buscar y reemplazar global (preview primero)
```powershell
$args = '{"pattern":"foo","replacement":"bar","dryRun":true,"caseSensitive":false}'
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "find_and_replace_in_scripts" -Args $args
```
Solo después de confirmar el preview con el usuario, ejecuta sin `dryRun`.

### Verificar errores de sintaxis
```powershell
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "get_script_analysis" -Args '{"instancePath":"game.ServerScriptService"}'
```

### Crear un nuevo script
```powershell
$args = @{
    className = "Script"  # o "LocalScript", "ModuleScript"
    parent = "game.ServerScriptService"
    name = "MyNewScript"
    properties = @{ Source = "print('hello')" }
} | ConvertTo-Json -Compress
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "create_object" -Args $args
```

## Reglas

1. **`edit_script_lines` requiere match exacto y único** — si falla, lee el script primero
2. **Usa `get_script_analysis` después de cambios** para detectar errores
3. **Para cambios masivos, usa `dryRun: true` primero**
4. **Distingue `Script` (server), `LocalScript` (cliente), `ModuleScript` (librería)**

## Output

Para `grep_scripts` o listas: agrupa por archivo, muestra línea + contexto.
Para `get_script_source`: si pidieron un fragmento, muestra solo eso. Si pidieron el archivo completo, formátealo en un bloque luau.
Para errores de sintaxis: línea + columna + mensaje.
