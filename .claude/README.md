# Roblox Editor para Claude Code

Sistema completo para que Claude Code edite Roblox Studio en tiempo real vía el MCP server `robloxstudio-mcp`.

## Componentes

| Archivo | Rol |
|---------|-----|
| `agents/roblox-editor.md` | Agente especializado con conocimiento de Roblox/Luau y reglas de workflow |
| `commands/roblox.md` | `/roblox <acción>` — interacción general con Studio |
| `commands/roblox-setup.md` | `/roblox-setup` — instalación inicial (Node.js, plugin, mcp.json) |
| `commands/roblox-start.md` | `/roblox-start` — arranca el servidor MCP manualmente |
| `commands/roblox-status.md` | `/roblox-status` — health check completo del entorno |
| `commands/roblox-explore.md` | `/roblox-explore` — overview rápido del proyecto |
| `commands/roblox-script.md` | `/roblox-script` — operaciones enfocadas en scripts |
| `lib/roblox-mcp.ps1` | Helper PowerShell con auto-arranque, error handling, output grande |

## Instalación rápida (nueva máquina)

1. **Copiar archivos** a `~/.claude/` del usuario destino:
   - `agents/roblox-editor.md`
   - `commands/roblox*.md` (los 6)
   - `lib/roblox-mcp.ps1`
   - O alternativamente, dentro de un proyecto en `<proyecto>/.claude/` para uso por-proyecto.

2. **Ejecutar `/roblox-setup`** en Claude Code — instala Node.js, el plugin de Studio y configura `mcp.json`.

3. **Recargar VS Code** y abrir Roblox Studio con el plugin activo.

4. **Usar**: `/roblox crea un Part en Workspace`, etc.

## Cómo se conecta todo

```
[Claude Code] ──stdio──> [npx robloxstudio-mcp] ──HTTP:58741──> [Plugin en Studio]
                              │
                              └──MCP tools──> Studio API (DataModel, scripts, props...)
```

El servidor:
- Lo arranca Claude Code automáticamente vía `mcp.json`
- También se puede arrancar manual: `npx -y robloxstudio-mcp@latest`
- Expone un endpoint HTTP MCP en `localhost:58741/mcp`
- El plugin de Roblox Studio se conecta a ese endpoint

Las skills usan **PowerShell + HTTP** para llamar al servidor sin depender de que el MCP esté cargado en la sesión actual de Claude. Esto permite usar `/roblox` desde cualquier conversación, no solo las nuevas.

## Cómo compartir

### Opción A: Por usuario (global)
Copia las carpetas `agents/`, `commands/`, `lib/` a `~/.claude/` del otro usuario. Disponible en cualquier proyecto.

### Opción B: Por proyecto (Git)
Pon todo dentro de `<proyecto>/.claude/` y haz commit. Cualquiera que clone tendrá los skills automáticamente al abrir el proyecto en Claude Code.

```bash
git add .claude/
git commit -m "Add Roblox MCP agent and skills"
```

### Opción C: Repo público
Sube `.claude/` a un repo público como `roblox-claude-agent`. Otros pueden clonarlo dentro de `~/.claude/`:

```bash
cd ~/.claude && git clone https://github.com/tu-user/roblox-claude-agent .
```

## Requisitos

- Windows (los paths/PowerShell están adaptados a Windows; cross-platform requeriría adaptaciones)
- Node.js LTS (instalable con `winget install OpenJS.NodeJS.LTS`)
- Roblox Studio
- Claude Code (CLI o extensión VS Code)

## Troubleshooting rápido

| Problema | Solución |
|----------|----------|
| `/roblox` no responde | `/roblox-status` para diagnosticar |
| "Server offline" | `/roblox-start` o `npx -y robloxstudio-mcp@latest` |
| Plugin de Studio en "waiting" | File → Studio Settings → Security → Allow HTTP Requests |
| `npx` no encontrado | `winget install OpenJS.NodeJS.LTS`, recargar terminal |
| PowerShell bloquea scripts | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |

## Recursos

- MCP server: https://www.npmjs.com/package/robloxstudio-mcp
- Roblox API: https://create.roblox.com/docs/reference/engine
- Rojo: https://rojo.space/
