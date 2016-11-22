## 1.3.0
* Added: Inline hint system which automatically tracks changed variables when stepping through a program and marks these events within the source
* Added: Atom now auto-focuses when a running program is interrupted and the debugger is activated
* Improved: Variable and stacktrace sidebar
	* Improved: Style improvements for easier reading (all code and identifiers now in monospace, values colour-coded and stacktrace aligned into columns)
	* Fixed: Scrolling would also scroll the header out of view
	* Changed: Ratio is now fixed at 2:1 for variables:stack-trace
* Fixed: The "step-out" button was still enabled when at the top of the stack and would cause debugger errors if clicked

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
