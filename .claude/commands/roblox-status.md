---
name: roblox-status
description: Diagnóstico completo del setup de Roblox MCP. Verifica Node.js, plugin de Studio, servidor activo, conexión y permisos. Úsalo cuando algo no funcione.
---

Ejecuta un health check completo del entorno Roblox MCP. Reporta cada paso al usuario en una tabla.

## Verificaciones

### 1. Node.js disponible
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
$node = (Get-Command node -ErrorAction SilentlyContinue)
if ($node) { "OK: $((& node --version))" } else { "FAIL: Node.js no instalado. Run: winget install OpenJS.NodeJS.LTS" }
```

### 2. Plugin instalado en Roblox Studio
```powershell
$plugin = "$env:LOCALAPPDATA\Roblox\Plugins\MCPPlugin.rbxmx"
if (Test-Path $plugin) { "OK: $plugin" } else { "FAIL: plugin no instalado. Run: npx robloxstudio-mcp@latest --install-plugin" }
```

### 3. mcp.json configurado
```powershell
$mcpJson = "$HOME\.claude\mcp.json"
if (Test-Path $mcpJson) {
    $config = Get-Content $mcpJson | ConvertFrom-Json
    if ($config.mcpServers.robloxstudio) { "OK: robloxstudio configurado" } else { "FAIL: robloxstudio no está en mcp.json" }
} else { "FAIL: $mcpJson no existe" }
```

### 4. Helper script presente
```powershell
$helper = "$HOME\.claude\lib\roblox-mcp.ps1"
if (Test-Path $helper) { "OK: $helper" } else { "WARN: helper no instalado (opcional)" }
```

### 5. Servidor MCP corriendo
```powershell
try {
    $body = '{"jsonrpc":"2.0","method":"initialize","id":0,"params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"healthcheck","version":"1.0"}}}'
    Invoke-RestMethod -Uri "http://localhost:58741/mcp" -Method POST -Body $body -ContentType "application/json" -Headers @{"Accept"="application/json, text/event-stream"} -TimeoutSec 3 | Out-Null
    "OK: servidor activo en :58741"
} catch { "FAIL: servidor offline. Run /roblox-start" }
```

### 6. Plugin de Studio conectado al servidor
```powershell
try {
    $body = '{"jsonrpc":"2.0","method":"tools/call","id":1,"params":{"name":"get_place_info","arguments":{}}}'
    $r = Invoke-RestMethod -Uri "http://localhost:58741/mcp" -Method POST -Body $body -ContentType "application/json" -Headers @{"Accept"="application/json, text/event-stream"} -TimeoutSec 5
    $json = ($r -split "`n" | Where-Object { $_ -match '^data: ' } | Select-Object -First 1) -replace '^data: ', ''
    $info = ($json | ConvertFrom-Json).result.content[0].text | ConvertFrom-Json
    "OK: conectado a $($info.placeName) (placeId $($info.placeId))"
} catch { "FAIL: plugin de Studio no conectado. Abrir Studio y activar MCPPlugin" }
```

## Presenta el resultado

Muestra los 6 checks como tabla:

| # | Check | Estado |
|---|-------|--------|
| 1 | Node.js | ... |
| 2 | Plugin Studio | ... |
| 3 | mcp.json | ... |
| 4 | Helper script | ... |
| 5 | Servidor MCP | ... |
| 6 | Plugin conectado | ... |

Si algún FAIL aparece, sugiere la acción de fix correspondiente al final.
