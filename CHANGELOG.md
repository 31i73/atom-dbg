## 1.6.0
* Buttons for toggling stack/variable/breakpoint panels
* Added: Breakpoint management panel
* Fixed: Occasional malfunctions when removing breakpoints
* Improved: Character case throughout menus
* #### 1.6.1
	* Fixed: Corner case where the active debugger selection was not maintained in the debug panel ([vanossj](https://github.com/vanossj))
* #### 1.6.2
	* Fixed: Internal errors using the debug panel ([chuck-r](https://github.com/chuck-r))
* #### 1.6.3
	* Fixed: Error when filtering by keyboard in the config selection modal ([#31 - rwa96](https://github.com/31i73/atom-dbg/issues/31))
	* Fixed: Keyboard filter for selection modal did not clear from last time
	* Fixed: dbg would fail if watching the config files for updates failed for an unknown reason. This is now politely reported, instead ([#32 - wknapek](https://github.com/31i73/atom-dbg/issues/27))

## 1.5.0
* Improved: Now uses Atom 1.17 docks. Sidebars can now be resized, split, dragged or tabbed anywhere within Atom, and by default are docked onto the side of the screen
* Fixed: Incompatibilities with some themes/font-sizings ([#17 - cocoaway](https://github.com/31i73/atom-dbg/issues/17))
* Fixed: Error when trying to toggle breakpoint if a texteditor is not focused ([#15 - rohmer](https://github.com/31i73/atom-dbg/issues/15))

## 1.4.0
* Added: Debug configuration files. You can now save named debug configs, with custom options in project config files ([vanossj](https://github.com/vanossj))
	*  Added: You can now save configs from the debug configuration panel
* Changed: Pressing `F5` (dbg:pause-continue) to begin a new debug session now either prompts to select a debug config if configs are available, or shows the configuration panel
* Fixed: Depreciated shadowdom removed. Now Atom 1.13+ only  ([vanossj](https://github.com/vanossj))
* Changed: File paths are now relative, not absolute (in the case of debug config files, saved paths are relative to the location of this file)
* Improved: Debug configuration panel debugger dropdown now shows "descriptive" names, rather than debug identifiers
* #### 1.4.1
	* Fixed: Debugger selector on the custom panel did not function, and when saved would store incorrect debugger names

## 1.3.0
* Added: Inline hint system which automatically tracks changed variables when stepping through a program and marks these events within the source
* Added: Atom now auto-focuses when a running program is interrupted and the debugger is activated
* Improved: Variable and stacktrace sidebar
	* Improved: Style improvements for easier reading (all code and identifiers now in monospace, values colour-coded and stacktrace aligned into columns)
	* Fixed: Scrolling would also scroll the header out of view
	* Changed: Ratio is now fixed at 2:1 for variables:stack-trace
* Fixed: The "step-out" button was still enabled when at the top of the stack and would cause debugger errors if clicked
* #### 1.3.1
	* Fixed: Sidebar font sizes were too small with certain themes, and colours not always readable ([#6 - dcarrera](https://github.com/31i73/atom-dbg/issues/6))

## 1.2.0
* Added: Exciting new configuration panel for setting up debugs (thanks to [vanossj](https://github.com/vanossj)!)
	* Right-clicking a file from the treeview and selecting **Debug** will now open the config panel, with that path and working directory selected
* Added: Keyboard shortcuts:
	* `F5` now also begins a new debug session as well as pausing/continuing an existing. If no settings have yet been configured for debug, the custom debug panel will be opened instead
	* `ctrl-shift-F5` shows the debug configuration panel
* Added: A toggle button for showing variable types
* Added: You can now click in the gutter to toggle breakpoints in sourcefiles
* Improved: Variable tooltips now prettier, and include types
* Fixed: Continue/pause buttons were still clickable when active/disabled

## 1.1.0
* Added: API option for specifying stack frame error messages
	* `provideDbg` v1.1
* Added: Display of debug errors:
	* Stacktrace frames with errors are now highlighted
	* Current active lines now highlighted appropriately when on an error position

## 1.0.0
* Initial stable release
