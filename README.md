# mandel

A local-first signal aquarium for maps, feeds, markets, infrastructure, and other strange global patterns.

## What this is

- live world map + globe views
- news, markets, infrastructure, climate, aviation, maritime, and OSINT-style panels
- lots of local browser persistence
- optional desktop / Docker paths already in the repo

## The zero-terminal way to start

### Windows

1. Download or extract the repo.
2. Open the folder.
3. Double-click **RUN ME.bat**.
4. Wait for Mandel to wake up.
5. Your browser opens automatically.
6. Double-click **STOP.bat** when you are done.

### macOS / Linux

- Double-click **RUN ME.command** on macOS if your system allows it.
- Or run **RUN ME.sh**.

For the very human version of the instructions, read **README-FIRST.txt**.
For rescue steps, read **TROUBLESHOOTING.txt**.

## Default local URL

- `http://127.0.0.1:3000`
- If port 3000 is busy, the launcher picks the next free port and tells you which one.

## Local-first safety

Mandel now prefers localhost by default.

- Vite dev startup binds to `127.0.0.1` unless you deliberately override it.
- The launcher waits for the local URL before opening your browser.
- The launcher only stops the process tree it started itself.

If you want LAN exposure on purpose, set `WM_HOST=0.0.0.0` yourself before launching.

## Local data lives here

Mandel stores local state in:

- browser storage for the local site (`localStorage`, `IndexedDB`, browser cache)
- `.launcher/` for launcher logs + PID files
- `node_modules/` if the launcher installs local dependencies

Use the **Reset local data** button in the footer dock for the easiest cleanup.

## Developer commands

If you do like terminals after all:

```bash
npm install
npm run dev
npm run typecheck
npm run test:data
npm run lint:md
```

## Notes

- Many upstream links, APIs, and deployment references still point at the existing `worldmonitor` infrastructure.
