<div align="center">

# 🎮 Roblox Studio Agent for Claude Code

**Edita tus juegos de Roblox Studio en tiempo real hablando con Claude.**

Un set de skills, un agente especializado y un helper de PowerShell que conectan **Claude Code** con **Roblox Studio** vía el [MCP de Roblox](https://www.npmjs.com/package/robloxstudio-mcp). Modifica scripts, construye escenas, ejecuta playtests y debuggea — todo con lenguaje natural desde tu editor.

[![Claude Code](https://img.shields.io/badge/Claude_Code-Compatible-D97706?style=for-the-badge)](https://claude.com/claude-code)
[![Roblox Studio](https://img.shields.io/badge/Roblox_Studio-Live_Edit-E2231A?style=for-the-badge&logo=roblox&logoColor=white)](https://create.roblox.com/)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

</div>

---

## 📑 Tabla de contenidos

- [¿Qué hace?](#-qué-hace)
- [Demo](#-demo)
- [Instalación rápida](#-instalación-rápida)
- [Cómo funciona](#-cómo-funciona)
- [Skills disponibles](#-skills-disponibles)
- [Estructura del repo](#-estructura-del-repo)
- [Configuración](#-configuración)
- [Ejemplos de uso](#-ejemplos-de-uso)
- [Troubleshooting](#-troubleshooting)
- [Requisitos](#-requisitos)
- [Roadmap](#-roadmap)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

---

## ✨ ¿Qué hace?

| Capacidad | Descripción |
|-----------|-------------|
| 🔍 **Inspección en vivo** | Lee la jerarquía completa, propiedades y selección actual de Studio |
| ✏️ **Edición de scripts** | Modifica scripts existentes con cambios quirúrgicos o reescritura completa |
| 🏗️ **Construcción de escenas** | Crea Parts, modelos, UI y jerarquías completas en un solo prompt |
| 🐛 **Debug y playtest** | Inicia playtests, captura output, simula input y toma screenshots |
| ⚡ **Ejecución de Luau** | Corre código Luau directamente en el contexto del plugin |
| 🔌 **Auto-recovery** | El servidor MCP se inicia automáticamente si está caído |

---

## 🎬 Demo

```text
👤 /roblox crea un cubo azul de 10x10x10 en el centro del workspace

🤖 ✓ Creado game.Workspace.TestCube
   Tamaño: 10x10x10
   Posición: (0, 5, 0)
   Color: Bright blue
   Anclado: sí
```

```text
👤 /roblox los papeles del piso tienen Z-fighting, arréglalo

🤖 Encontré 78 tiles en game.Workspace.Lobby.Floor todos a Y=0.050.
   Aplicando stagger de 0.01 estudios entre cada uno...
   ✓ 78 tiles ajustados (Y range: 0.060 → 0.830)
```

```text
👤 /roblox-explore

🤖 # ChooseDoors (placeId: 83747541754245)

   ## Workspace
   - Lobby (Folder, 7 hijos)
     - Floor, Walls, Columns, Ceiling, Portal, Decorations, SpawnPoint
   - BasePJ (Model)

   ## Scripts
   - ServerScriptService: GameInit.luau
   - StarterPlayerScripts: ClientController.client.luau
   - ReplicatedStorage: SharedTypes.luau
```

---

## 🚀 Instalación rápida

### Opción 1: Por proyecto (recomendado para equipos)

```bash
cd <tu-proyecto-roblox>
git clone https://github.com/MacWilliXD/Roblox-Studio-Agent.git temp
cp -r temp/.claude .
rm -rf temp
```

### Opción 2: Global para tu usuario

```powershell
git clone https://github.com/MacWilliXD/Roblox-Studio-Agent.git "$HOME\.claude-roblox"
xcopy /E /I "$HOME\.claude-roblox\.claude\agents" "$HOME\.claude\agents"
xcopy /E /I "$HOME\.claude-roblox\.claude\commands" "$HOME\.claude\commands"
xcopy /E /I "$HOME\.claude-roblox\.claude\lib" "$HOME\.claude\lib"
```

### Después de copiar los archivos:

1. Abre Claude Code en tu proyecto y ejecuta:
   ```
   /roblox-setup
   ```
   Esto instala Node.js (si falta), el plugin de Roblox Studio y configura `mcp.json`.

2. Abre **Roblox Studio**, activa el plugin **MCPPlugin** y verifica:
   ```
   File → Studio Settings → Security → Allow HTTP Requests ✓
   ```

3. **Recarga VS Code** (`Ctrl+Shift+P` → `Developer: Reload Window`).

4. Verifica el setup:
   ```
   /roblox-status
   ```

5. ¡Listo! Ahora puedes usar:
   ```
   /roblox crea un Part en Workspace
   ```

---

## 🏗️ Cómo funciona

```text
┌─────────────────┐       ┌──────────────────────┐       ┌────────────────────┐
│   Claude Code   │──────▶│  robloxstudio-mcp    │──────▶│  Plugin en Studio  │
│   (VS Code)     │ stdio │  (HTTP :58741)       │ HTTP  │  (MCPPlugin.rbxmx) │
└─────────────────┘       └──────────────────────┘       └─────────┬──────────┘
        │                            ▲                              │
        │                            │                              ▼
        │  PowerShell helper         │                    ┌────────────────────┐
        └────────────────────────────┘                    │  Roblox Studio     │
                  HTTP directo                             │  (DataModel,       │
                                                           │   scripts, props)  │
                                                           └────────────────────┘
```

**El truco:** las skills usan un helper PowerShell que llama al endpoint HTTP del MCP server directamente. Esto significa que `/roblox` funciona en **cualquier conversación de Claude Code**, no solo en sesiones donde el MCP está cargado al inicio.

### Flujo de una llamada

1. Escribes `/roblox crea un cubo` en Claude Code
2. Claude lee el skill `roblox.md` y decide usar `create_object`
3. Construye un JSON-RPC request y lo envía vía PowerShell al servidor MCP local
4. El servidor reenvía la orden al plugin de Roblox Studio
5. El plugin ejecuta la operación y devuelve el resultado
6. Claude formatea la respuesta para ti

---

## 🛠️ Skills disponibles

| Skill | Función | Ejemplo |
|-------|---------|---------|
| [`/roblox`](.claude/commands/roblox.md) | Interacción general con Studio | `/roblox crea un Part rojo` |
| [`/roblox-setup`](.claude/commands/roblox-setup.md) | Instalación inicial completa | `/roblox-setup` |
| [`/roblox-start`](.claude/commands/roblox-start.md) | Arranca el servidor MCP | `/roblox-start` |
| [`/roblox-status`](.claude/commands/roblox-status.md) | Diagnóstico del entorno | `/roblox-status` |
| [`/roblox-explore`](.claude/commands/roblox-explore.md) | Overview del proyecto abierto | `/roblox-explore` |
| [`/roblox-script`](.claude/commands/roblox-script.md) | Operaciones enfocadas en scripts | `/roblox-script edita GameInit.luau` |

### Agente especializado

[`roblox-editor`](.claude/agents/roblox-editor.md) — Sub-agente con conocimiento profundo de:
- 50+ tools del MCP de Roblox con args y casos de uso
- Patrones comunes de Luau (RemoteEvent, Tween, DataStore, CollectionService)
- Servicios de Roblox y APIs de uso frecuente
- Reglas de seguridad (no usar `undo` después de `execute_luau`, etc.)

---

## 📂 Estructura del repo

```
.
├── .claude/
│   ├── agents/
│   │   └── roblox-editor.md          # Sub-agente con conocimiento profundo
│   ├── commands/
│   │   ├── roblox.md                 # /roblox <acción>
│   │   ├── roblox-setup.md           # /roblox-setup
│   │   ├── roblox-start.md           # /roblox-start
│   │   ├── roblox-status.md          # /roblox-status
│   │   ├── roblox-explore.md         # /roblox-explore
│   │   └── roblox-script.md          # /roblox-script
│   ├── lib/
│   │   └── roblox-mcp.ps1            # Helper PowerShell con auto-arranque
│   └── settings.local.json           # Permisos auto-aprobados
└── README.md                         # Este archivo
```

---

## ⚙️ Configuración

### `mcp.json` (lo crea `/roblox-setup`)

Ubicación: `%USERPROFILE%\.claude\mcp.json`

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

### Permisos del proyecto

`settings.local.json` ya viene con permisos pre-aprobados para evitar prompts:

```json
{
  "permissions": {
    "allow": [
      "PowerShell(*)",
      "Bash(mkdir -p *)",
      "Bash(cp *)",
      "Bash(find *)"
    ]
  }
}
```

> **⚠️ Nota de seguridad:** `PowerShell(*)` permite ejecutar cualquier comando PowerShell sin confirmación. Si prefieres ser más restrictivo, reemplázalo por:
> ```json
> "PowerShell(*roblox-mcp.ps1*)",
> "PowerShell(*localhost:58741*)",
> "PowerShell(*robloxstudio-mcp*)"
> ```

---

## 💡 Ejemplos de uso

<details>
<summary><b>🔨 Construir una escena</b></summary>

```
/roblox crea un piso de 100x1x100 en Workspace, anclado, color gris
/roblox encima del piso pon 4 columnas de 4x10x4 en las esquinas
/roblox agrega un SpawnLocation en el centro a Y=2
```

</details>

<details>
<summary><b>📝 Editar scripts</b></summary>

```
/roblox-script lee el script game.ServerScriptService.GameInit
/roblox-script en GameInit cambia "local maxPlayers = 8" por "local maxPlayers = 16"
/roblox-script busca todas las llamadas a "BadFunction" en los scripts
```

</details>

<details>
<summary><b>🐛 Debugging</b></summary>

```
/roblox inicia un playtest
/roblox muéstrame el output del log
/roblox toma una screenshot del viewport
/roblox detén el playtest
```

</details>

<details>
<summary><b>🔧 Operaciones masivas</b></summary>

```
/roblox encuentra todos los Parts con Anchored=false en Workspace y anclalos
/roblox renombra todos los Parts en Lobby.Decorations con prefijo "Deco_"
/roblox los tiles del piso tienen Z-fighting, escalonalos en Y
```

</details>

<details>
<summary><b>🎨 Trabajar con UI</b></summary>

```
/roblox crea una pantalla de loading en StarterGui con un Frame negro semitransparente y un texto "Loading..."
/roblox agrega un botón "Play" centrado de 200x60 con esquinas redondeadas
```

</details>

---

## 🐛 Troubleshooting

| Problema | Solución |
|----------|----------|
| `/roblox` no responde | Ejecuta `/roblox-status` para diagnosticar |
| `Server offline` o connection refused | `/roblox-start` o `npx -y robloxstudio-mcp@latest` |
| Plugin de Studio en estado "waiting" | `File → Studio Settings → Security → Allow HTTP Requests` |
| `npx` no encontrado | `winget install OpenJS.NodeJS.LTS`, luego recarga la terminal |
| PowerShell bloquea scripts (`.ps1`) | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Skills nuevos no aparecen al teclear `/` | `Ctrl+Shift+P` → `Developer: Reload Window` |
| `instancePath ... no es miembro` | El path no existe — usa `search_objects` o `get_instance_children` primero |
| Output truncado en respuestas grandes | Usa el helper con `-SaveLarge` o pide filtros más específicos |

Para diagnóstico completo:

```
/roblox-status
```

Te dará una tabla con el estado de los 6 componentes:
1. Node.js
2. Plugin de Roblox Studio instalado
3. `mcp.json` configurado
4. Helper script presente
5. Servidor MCP corriendo
6. Plugin conectado al servidor

---

## 📋 Requisitos

- **OS:** Windows 10/11 (paths y PowerShell adaptados; Mac/Linux requeriría adaptaciones)
- **Node.js:** v18+ (`winget install OpenJS.NodeJS.LTS`)
- **Roblox Studio:** versión actual
- **Claude Code:** CLI o extensión de VS Code ([instalación](https://docs.claude.com/en/docs/claude-code))
- **PowerShell:** 5.1 o superior (incluido en Windows)

---

## 🗺️ Roadmap

- [ ] Soporte cross-platform (macOS/Linux)
- [ ] Skill `/roblox-build` para procedural builds
- [ ] Skill `/roblox-test` con assertions automatizadas
- [ ] Templates de proyectos (lobby, FPS base, RPG starter)
- [ ] Soporte para multi-place (DataStores compartidos)
- [ ] Dashboard de output del playtest en tiempo real

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Si encuentras un bug, tienes una idea o quieres agregar un skill nuevo:

1. Fork el repo
2. Crea una rama (`git checkout -b feat/mi-skill`)
3. Commit tus cambios (`git commit -m 'Add: skill /roblox-foo'`)
4. Push a la rama (`git push origin feat/mi-skill`)
5. Abre un Pull Request

### Ideas para contribuir

- Skills nuevos para casos de uso específicos
- Adaptación a macOS/Linux (Bash en lugar de PowerShell)
- Documentación en otros idiomas
- Tests de integración para los skills
- Templates de proyectos Roblox

---

## 📜 Licencia

[MIT](LICENSE) © [MacWilliXD](https://github.com/MacWilliXD)

---

## 🙏 Agradecimientos

- [`robloxstudio-mcp`](https://www.npmjs.com/package/robloxstudio-mcp) — el MCP server que hace todo posible
- [Anthropic Claude Code](https://claude.com/claude-code) — la plataforma

---

<div align="center">

**¿Te resulta útil?** ⭐ Dale una estrella al repo y compártelo con otros devs de Roblox.

[Reportar bug](https://github.com/MacWilliXD/Roblox-Studio-Agent/issues) · [Solicitar feature](https://github.com/MacWilliXD/Roblox-Studio-Agent/issues) · [Discusiones](https://github.com/MacWilliXD/Roblox-Studio-Agent/discussions)

</div>
