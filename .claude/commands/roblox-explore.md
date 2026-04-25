---
name: roblox-explore
description: Resumen rápido del proyecto de Roblox abierto en Studio. Lista servicios, estructura del Workspace, scripts existentes y selección actual. Útil para empezar una sesión sin contexto.
---

Da un overview compacto del estado actual de Roblox Studio. El argumento opcional limita el alcance: $ARGUMENTS

## Ejecuta en paralelo

Llama estas 4 tools y combina los resultados:

```powershell
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "get_place_info" -Args "{}"
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "get_instance_children" -Args '{"instancePath":"game.Workspace"}'
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "get_project_structure" -Args '{"maxDepth":2,"scriptsOnly":true}'
& "$HOME\.claude\lib\roblox-mcp.ps1" -Tool "get_selection" -Args "{}"
```

## Presenta como

```
# {placeName} (placeId: {placeId})

## Workspace
- {Folder/Model 1} ({className}, {count} hijos)
- {Folder/Model 2} ...

## Scripts
- ServerScriptService:
  - {script1.luau}
  - ...
- StarterPlayerScripts:
  - {script1.client.luau}
- ReplicatedStorage:
  - {module1.luau}

## Selección actual
{N objetos seleccionados o "nada seleccionado"}
```

Si $ARGUMENTS contiene un path específico (ej: "game.Workspace.Lobby"), expande solo esa rama con `get_descendants` en lugar del overview general.

## Tips

- No incluyas `Terrain` o `Camera` en el listado del Workspace (siempre están)
- Si hay >20 hijos en algún folder, agrupa por className y di "(15 Parts)" en vez de listarlos
- Resalta nombres como `BasePJ`, `Lobby`, etc. que probablemente sean importantes
