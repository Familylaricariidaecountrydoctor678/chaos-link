# Chaos Link

Chaos Link is a small real-time control system for a private CS2 chaos session:

- any number of friends open the same web room;
- one Windows gaming PC runs the local agent;
- effect cooldowns are owned by the server and shared by every controller;
- the agent accepts only allow-listed effect identifiers and delegates them to AutoHotkey v2.

## Project layout

```text
apps/server/   ASP.NET Core WebSocket server and room state
apps/web/      React + Vite responsive controller UI
apps/agent/    .NET console agent for the gaming PC
ahk/           AutoHotkey v2 effect runner
scripts/       Headless smoke test
docs/          UI concept and protocol notes
```

## Requirements

- .NET SDK 9
- Node.js 20+
- AutoHotkey v2 on the gaming PC

## Development

Install and build the web application:

```powershell
cd apps/web
npm install
npm run build
```

Start the server:

```powershell
cd apps/server
dotnet run --urls http://0.0.0.0:5075
```

Open `http://localhost:5075` locally. Friends on the same network can use
`http://<gaming-pc-ip>:5075`. For internet access, put the server behind HTTPS
and WSS (for example a reverse proxy or a private tunnel); do not expose the
agent itself.

Start the gaming-PC agent in another terminal:

```powershell
cd apps/agent
dotnet run
```

The development defaults are:

- room: `K7M2`
- controller key: `friend-access`
- admin key: `admin-access`
- agent key: `agent-secret`

Change all three values before making the service reachable from the internet.
Server values live in `apps/server/appsettings.json`; agent values live in
`apps/agent/appsettings.json`.

The web panel asks for a display name, role, room code, and matching key. Any
number of friends may use the controller key. Only the administrator can pause
or resume all effects. Keys are kept only in the browser's session storage.

## Local production host for a reverse proxy

Build a deploy directory with fresh random controller and agent keys:

```powershell
.\scripts\publish-chaos-link.ps1
```

Start the website and gaming-PC agent without visible windows:

```powershell
.\scripts\start-chaos-link.ps1
```

The server listens on all local network interfaces by default, so another device
on the same LAN can open `http://<gaming-pc-ip>:5075`. The reverse-proxy upstream
remains `http://127.0.0.1:5075`. Point your HTTPS/WSS reverse
proxy to this address and preserve WebSocket upgrade headers. The room code,
controller key, admin key, and upstream are stored locally in `.runtime/access.json`.

Stop both processes:

```powershell
.\scripts\stop-chaos-link.ps1
```

## AutoHotkey

Set `AutoHotkeyPath` in `apps/agent/appsettings.json` if AutoHotkey is not on
`PATH`. The agent launches a controlled AHK process for each active effect and
tracks it until completion. Effects are sent to the active Windows session
without checking which window is in the foreground. Use the administrator pause
as the global stop switch.

Screamer media is loaded at activation time. Put any number of PNG images in
`deploy\screamer\images` and WAV/MP3/WMA/M4A files in
`deploy\screamer\sounds`; one image and one sound are selected independently at
random. Empty folders fall back to the built-in warning image and beeps.

In the administrator panel, click an online guest to block that display name
for 30 seconds. The cooldown field under every effect changes the shared room
cooldown for future activations (0-3600 seconds).

Emergency release:

- press `Ctrl+Shift+F12` on the gaming PC; or
- use **Экстренная пауза** in the web panel.

Both paths release held keys and disable temporary input blocks.

## Headless smoke test

With the server running:

```powershell
node scripts/smoke-test.mjs
```

The test connects one agent and two controllers, triggers an effect, verifies
that both controllers receive the same cooldown, and confirms that an immediate
second trigger is rejected.

## Safety notes

Chaos Link does not inject DLLs, inspect game memory, detect enemies, or expose
a remote shell. Nevertheless, game policies can change and no third-party tool
can promise VAC safety. Use it in private/community games and keep CS2 Trusted
Mode enabled. Driver-level input interception is deliberately not used.
