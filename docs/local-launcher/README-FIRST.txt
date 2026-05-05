MANDEL // README FIRST
======================

Hi. Deep breath. You do not need a terminal for this.

This runs locally on your own computer by default.
Nothing is supposed to open to your whole network unless you deliberately change the config.

HOW TO START
------------
1. Open this folder.
2. Double-click RUN ME.bat.
3. Wait while Mandel wakes up.
4. Your browser should open automatically.
5. If Windows asks whether you trust the file, choose the option that lets you run it.

HOW TO STOP
-----------
Double-click STOP.bat.
That tells the local app to shut down and cleans up its launcher state.

WHAT OPENS IN YOUR BROWSER
--------------------------
Mandel opens in your default browser at:
http://127.0.0.1:3000

If port 3000 is already busy, Mandel may quietly pick the next free port instead.
The launcher window will tell you the exact address.

WHAT TO DO IF WINDOWS WARNS YOU
-------------------------------
If Windows says the script came from the internet or asks whether you want to run it:
- choose More info if needed
- choose Run anyway if you trust this copy
- if ZIP extraction marked everything as blocked, right-click the ZIP before extracting and look for an Unblock checkbox in Properties

WHAT TO DO IF DOCKER / NODE / PYTHON IS MISSING
-----------------------------------------------
This repo currently launches best with Node.js.
If Node.js is missing, RUN ME.bat will tell you.
Install Node.js, then double-click RUN ME.bat again.

If Mandel ever falls back to Docker, the launcher will say so plainly.
In that case install Docker Desktop, open Docker Desktop, wait until it is fully running, then try again.

WHERE YOUR DATA IS STORED
-------------------------
Mandel keeps its local app state in a few places:
- your browser storage for http://127.0.0.1:3000 (localStorage, IndexedDB, cache)
- the .launcher folder inside this repo (temporary launcher log + PID files)
- node_modules inside this folder if the launcher installs packages for you

HOW TO RESET THE APP
--------------------
Easy path:
- open Mandel
- use the “Reset local data” button in the local status dock

Manual path:
- close Mandel with STOP.bat
- delete the .launcher folder
- clear this browser site's storage for http://127.0.0.1:3000
- if you want a full clean slate, you can also delete node_modules and let RUN ME.bat rebuild it next time

HOW TO UPDATE THE APP
---------------------
If you downloaded a ZIP:
- download a fresh ZIP
- extract it to a new folder
- copy over anything you personally changed if you want to keep it

If you cloned the repo:
- pull the latest changes the usual Git way
- then double-click RUN ME.bat again

LOCAL-ONLY SAFETY
-----------------
By default Mandel binds to 127.0.0.1 only.
That means it is meant to stay on your own machine.
If you ever want to expose it to your network, you must change the host setting yourself on purpose.

IF SOMETHING GOES SIDEWAYS
--------------------------
Read docs/local-launcher/TROUBLESHOOTING.txt.
It was written for bad days.
