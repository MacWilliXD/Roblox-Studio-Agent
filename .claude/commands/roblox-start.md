---
name: roblox-start
description: Inicia el servidor MCP de Roblox Studio manualmente. Úsalo cuando el servidor no esté corriendo o Claude Code no lo haya iniciado automáticamente.
---

Inicia el servidor MCP de Roblox Studio y verifica la conexión.

## Pasos

### 1. Verificar si ya está corriendo
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
try {
    $r = Invoke-RestMethod -Uri "http://localhost:58741/mcp" -Method POST -Body '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' -ContentType "application/json" -Headers @{"Accept"="application/json, text/event-stream"} -ErrorAction Stop
    Write-Host "Servidor ACTIVO"
} catch {
    Write-Host "Servidor OFFLINE - iniciando..."
}
```

### 2. Si está offline, iniciarlo
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
& "C:\Program Files\nodejs\npx.cmd" -y robloxstudio-mcp@latest
```
Ejecutar en background y esperar 4 segundos.

### 3. Verificar que levantó
```powershell
Start-Sleep -Seconds 4
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
$body = '{"jsonrpc":"2.0","method":"tools/call","id":1,"params":{"name":"get_place_info","arguments":{}}}'
$r = Invoke-RestMethod -Uri "http://localhost:58741/mcp" -Method POST -Body $body -ContentType "application/json" -Headers @{"Accept"="application/json, text/event-stream"}
$json = ($r -split "`n" | Where-Object { $_ -match '^data: ' } | Select-Object -First 1) -replace '^data: ', ''
($json | ConvertFrom-Json).result.content | ForEach-Object { $_.text }
```

Si devuelve info del lugar (placeName, placeId), todo está conectado.

### Troubleshooting
- Si `npx` no se encuentra: ejecutar `/roblox-setup` primero
- Si el servidor inicia pero dice "Waiting for Studio plugin": abrir Roblox Studio y activar MCPPlugin en la pestaña Plugins
- Si Studio muestra "waiting" en el plugin: ir a **File → Studio Settings → Security → Allow HTTP Requests**
