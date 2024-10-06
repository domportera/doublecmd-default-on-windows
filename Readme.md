
# Replace Windows Explorer with Double Commander
This repo provides scripts enabling you to change the default file manager to one of your choice. It is pre-configured for Double Commander, however modifying it for another file manager would be fairly straightforward.

Disclaimer: I have only tested this on my personal Windows 10 machine. I have little reason to believe it won't work for you, but beware and back up your registry before proceeding. Most of you won't. The smart ones will. I am not very smart.

## Dependencies
Powershell - the modern version. `install-powershell.bat` can help you get it if needed.

## Recommended installatiom
Place this directory/repo to your C:/ drive in a folder called "doublecmd", such that the full path of this file is `C:/doublecmd/Readme.md`

Doing this ensurea that you do not need to modify the scripts ptovided to account for the location of this folder.

## Double Commander as the default explorer on Windows
Double click the included `doublecmd.reg` file. To revert back to explorer, double-click `explorer.reg`

Note - this will not work if you are using a portable installation. If that is the case, you must modify `doublecmd.reg` accordingly.


## Win + E hotkey
### Method 1 - Registry
Double click `doublecmd-hotkey.reg`
To revert, double click `explorer-hotkey.reg`

### Method 2 - Powertoys
Using [Powertoys Keyboard Manager](https://learn.microsoft.com/en-us/windows/powertoys/keyboard-manager), one could replace the functionality of the Win + E shortcut without mucking about in their registry and in a way that's easy to revert with a gui or just by ending its process.

Create a new keyboard shortcut with the following settings:

- Action - Run Program
- App - `C:\Windows\SysWOW64\wscript.exe`
- Args - `invisible.vbs doublecmdAsExplorer.bat`
- Start In - `C:/doublecmd` or the folder with all these scripts
- If running - `Start another`


You may want to also set Double Commander to only allow one instance (Configuration -> Behaviors -> Allow only one copy of DC at a time)
