---
name: roblox-setup
description: Instala y configura el MCP de Roblox Studio desde cero. Instala Node.js si no está, el plugin de Studio, y configura mcp.json. Úsalo la primera vez o para diagnosticar problemas de conexión.
---

Configura el entorno completo para conectar Claude Code con Roblox Studio.

## Pasos a ejecutar en orden

### 1. Verificar Node.js
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
node --version
```
Si falla, instalarlo:
```powershell
winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
```
Luego refrescar PATH:
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
```

### 2. Habilitar ejecución de scripts PowerShell
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### 3. Instalar plugin de Roblox Studio
```powershell
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
npx robloxstudio-mcp@latest --install-plugin
```
Confirma que diga: `Installed to C:\Users\...\AppData\Local\Roblox\Plugins\MCPPlugin.rbxmx`

### 4. Configurar mcp.json para Claude Code
Escribe el archivo `~/.claude/mcp.json` con este contenido:
```json
{
  "mcpServers": {
    "robloxstudio": {
      "command": "C:\\Program Files\\nodejs\\npx.cmd",
      "args": ["-y", "robloxstudio-mcp@latest"]
    }
  }
}
```

### 5. Verificar que todo esté listo
Muestra al usuario un resumen:
- Node.js version
- Plugin instalado en `%LOCALAPPDATA%\Roblox\Plugins\MCPPlugin.rbxmx` (sí/no)
- mcp.json configurado (sí/no)

### 6. Instrucciones finales para el usuario
Dile que haga:
1. Abrir Roblox Studio con un proyecto
2. Ir a la pestaña **Plugins** → activar **MCPPlugin**
3. En Studio: **File → Studio Settings → Security** → activar **Allow HTTP Requests**
4. Recargar VS Code: `Ctrl+Shift+P` → **Developer: Reload Window**
5. Abrir una **nueva conversación** en Claude Code
6. En la nueva conversación usar `/roblox-start` para iniciar el servidor

Confirma cada paso al usuario y maneja errores que aparezcan.
