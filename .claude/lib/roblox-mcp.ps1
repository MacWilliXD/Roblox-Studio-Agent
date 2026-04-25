# roblox-mcp.ps1 - Helper for calling robloxstudio-mcp HTTP API
# Usage: & "$HOME/.claude/lib/roblox-mcp.ps1" -Tool "get_place_info" -Args "{}"
#        & "$HOME/.claude/lib/roblox-mcp.ps1" -Tool "create_object" -Args '{"className":"Part","parent":"game.Workspace"}' -AutoStart

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Tool,

    [Parameter(Position=1)]
    [string]$Args = "{}",

    [string]$ServerUrl = "http://localhost:58741/mcp",

    # If true, attempt to start the server when offline
    [switch]$AutoStart,

    # If true, return raw JSON instead of just the text content
    [switch]$Raw,

    # If true, save large responses to a temp file and return the path
    [switch]$SaveLarge,

    [int]$LargeThresholdKB = 25
)

$ErrorActionPreference = "Stop"

# Refresh PATH so node/npx are findable
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

$headers = @{
    "Accept" = "application/json, text/event-stream"
    "Content-Type" = "application/json"
}

function Test-MCPServer {
    try {
        $body = '{"jsonrpc":"2.0","method":"initialize","id":0,"params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"healthcheck","version":"1.0"}}}'
        $null = Invoke-RestMethod -Uri $ServerUrl -Method POST -Body $body -ContentType "application/json" -Headers $headers -TimeoutSec 3 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Start-MCPServer {
    $npx = "C:\Program Files\nodejs\npx.cmd"
    if (-not (Test-Path $npx)) {
        $npx = "npx.cmd"
    }
    Start-Process $npx -ArgumentList "-y robloxstudio-mcp@latest" -NoNewWindow
    $deadline = (Get-Date).AddSeconds(15)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if (Test-MCPServer) { return $true }
    }
    return $false
}

# Check connectivity
if (-not (Test-MCPServer)) {
    if ($AutoStart) {
        Write-Host "MCP server offline, starting..." -ForegroundColor Yellow
        if (-not (Start-MCPServer)) {
            Write-Error "MCP server is offline and could not be started. Check Node.js install and run /roblox-setup."
            exit 1
        }
    } else {
        Write-Error "MCP server offline at $ServerUrl. Start it with: & '$PSCommandPath' -Tool $Tool -AutoStart  (or run /roblox-start)"
        exit 1
    }
}

# Build and send the tool call
try {
    $argsObj = $Args | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Invalid JSON in -Args: $Args"
    exit 1
}

$payload = @{
    jsonrpc = "2.0"
    method = "tools/call"
    id = 1
    params = @{
        name = $Tool
        arguments = $argsObj
    }
} | ConvertTo-Json -Depth 30 -Compress

try {
    $response = Invoke-RestMethod -Uri $ServerUrl -Method POST -Body $payload -ContentType "application/json" -Headers $headers
} catch {
    Write-Error "MCP call failed: $_"
    exit 1
}

# Parse SSE response
$jsonLine = ($response -split "`n" | Where-Object { $_ -match '^data: ' } | Select-Object -First 1) -replace '^data: ', ''
if (-not $jsonLine) {
    Write-Error "Empty response from MCP server"
    exit 1
}

$result = $jsonLine | ConvertFrom-Json

if ($result.error) {
    Write-Error "MCP tool error [$($result.error.code)]: $($result.error.message)"
    exit 1
}

if ($Raw) {
    $jsonLine
    return
}

$texts = $result.result.content | ForEach-Object { $_.text }
$output = $texts -join "`n"

# Handle large outputs
if ($SaveLarge -and $output.Length -gt ($LargeThresholdKB * 1024)) {
    $tempFile = [System.IO.Path]::GetTempFileName() + ".json"
    $output | Out-File -FilePath $tempFile -Encoding utf8
    Write-Host "[Large output saved to: $tempFile]"
    return
}

$output
