Ui = require './Ui'
Toolbar = require './view/Toolbar'
Sidebar = require './view/Sidebar'
CustomPanel = require './view/CustomPanel'

{CompositeDisposable, Emitter} = require 'atom'

module.exports = Debug =
	provider: null
	ui: null
	toolbar: null
	atomToolbar: null
	sidebar: null
	atomSidebar: null
	customPanel: null
	atomCustomPanel: null
	disposable: null
	buggers: []
	activeBugger: null
	breakpoints: []

	activate: (state) ->
		@provider = new Emitter()

		@provider.debug = @debug.bind this
		@provider.stop = @stop.bind this

		@provider.continue = @continue.bind this
		@provider.pause = @pause.bind this
		@provider.pause_continue = => if @ui.isPaused then @continue() else @pause()

		@provider.stepIn = @stepIn.bind this
		@provider.stepOver = @stepOver.bind this
		@provider.stepOut = @stepOut.bind this

		@provider.addBreakpoint = @addBreakpoint.bind this
		@provider.removeBreakpoint = @removeBreakpoint.bind this
		@provider.toggleBreakpoint = @toggleBreakpoint.bind this
		@provider.getBreakpoints = @getBreakpoints.bind this
		@provider.hasBreakpoint = @hasBreakpoint.bind this

		@ui = new Ui this

		@toolbar = new Toolbar this
		@atomToolbar = atom.workspace.addBottomPanel item: @toolbar.getElement(), visible: false, priority:200

		@sidebar = new Sidebar this
		@atomSidebar = atom.workspace.addRightPanel item: @sidebar.getElement(), visible: false, priority:200

		@customPanel = new CustomPanel this
		@atomCustomPanel = atom.workspace.addBottomPanel item: @customPanel.getElement(), visible: false, priority:200
		@customPanel.emitter.on 'close', =>
			@atomCustomPanel.hide()

		@disposable = new CompositeDisposable
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:custom-debug': => @customDebug()
		@disposable.add atom.commands.add '.tree-view .file', 'dbg:custom-debug': =>
			selectedFile = document.querySelector '.tree-view .file.selected [data-path]'
			if selectedFile!=null
				@customDebug
					path: selectedFile.dataset.path
					cwd: (require 'path').dirname(selectedFile.dataset.path)
					args: []
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:stop': => @stop()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:continue': => @continue()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:pause': => @pause()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:pause-continue': =>
			if @activeBugger
				if @ui.isPaused then @continue() else @pause()
			else
				options = @customPanel.getOptions()
				if options.path
					@debug options
				else
					@customDebug()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:step-over': => @stepOver()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:step-in': => @stepIn()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:step-out': => @stepOut()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:toggle-breakpoint': =>
			textEditor = atom.workspace.getActiveTextEditor()
			if textEditor!=null
				pos = textEditor.getCursorBufferPosition()
				@toggleBreakpoint textEditor.getPath(), pos.row+1
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:clear-breakpoints': =>
			@clearBreakpoints()
		@disposable.add atom.commands.add '.debug-custom-panel', 'dbg:custom-confirm': => @customPanel.startDebugging()
		@disposable.add atom.commands.add 'atom-workspace', 'core:cancel': => @atomCustomPanel.hide()

		# install any text editors which are or become sourcecode (give them a clickable gutter)
		@disposable.add atom.workspace.observeTextEditors (textEditor) =>
			disposed = false
			@disposable.add observeGrammar = textEditor.observeGrammar (grammar) =>
				if /^source\./.test grammar.scopeName
					@installTextEditor textEditor
					disposed = true
					observeGrammar?.dispose()

			if disposed then observeGrammar.dispose()

		# restore previous breakpoints
		if state.breakpoints
			for breakpoint in state.breakpoints
				@addBreakpoint breakpoint.path, breakpoint.line

	deactivate: ->
		@disposable.dispose()

	serialize: ->
		data =
			breakpoints: []

		for breakpoint in @breakpoints
			data.breakpoints.push
				path: breakpoint.path
				line: breakpoint.line

		return data

	installTextEditor: (textEditor) ->
		path = textEditor.getPath()
		gutter = textEditor.gutterWithName('debug-gutter')

		if gutter then return

		gutter = textEditor.addGutter
			name: 'debug-gutter'
			priority: -200
			visible: true

		for breakpoint in @breakpoints
			if breakpoint.path == path
				marker = textEditor.markBufferRange [[breakpoint.line-1, 0], [breakpoint.line-1, 0]]
				gutter.decorateMarker marker,
					type: 'line-number'
					'class': 'debug-breakpoint'
				breakpoint.markers.push marker

		getEventRow = (event) ->
			screenPos = textEditorElement.component.screenPositionForMouseEvent event
			bufferPos = textEditor.bufferPositionForScreenPosition screenPos
			return bufferPos.row

		textEditorElement = textEditor.getElement()
		gutterContainer = textEditorElement.shadowRoot.querySelector '.gutter-container'
		gutterContainer.addEventListener 'mousemove', (event) =>
			row = getEventRow event

			marker = textEditor.markBufferRange [[row, 0], [row, 0]]
			@breakpointHint?.destroy()
			@breakpointHint = gutter.decorateMarker marker,
				type: 'line-number'
				'class': 'debug-breakpoint-hint'

		(atom.views.getView gutter).addEventListener 'click', (event) =>
			row = getEventRow event
			@toggleBreakpoint textEditor.getPath(), row+1

		gutterContainer.addEventListener 'mouseout', =>
			@breakpointHint?.destroy()
			@breakpointHint = null


	debug: (options) ->
		return new Promise (resolve) =>
			if options['debugger']
				for bugger in @buggers
					if bugger.name == options['debugger']
						@debugWithDebugger bugger, options
						resolve true
						return

				resolve false
				return

			resolved = false
			promises = []
			for bugger in @buggers
				promises.push (bugger.canHandleOptions options).then (success) =>
					if !resolved and success
						resolved = true
						resolve true
						@debugWithDebugger bugger, options

			(Promise.all promises).then =>
				if !resolved
					@ui.showError 'No compatible debugger for this'
					resolve false

	show: ->
		@atomToolbar.show()
		@toolbar.updateButtons()

	hide: ->
		@atomToolbar?.hide()
		@atomSidebar?.hide()

	customDebug: (options) ->
		@atomCustomPanel.show()
		if options then @customPanel.setOptions options
		@customPanel.focus()

	continue: ->
		unless @ui.isPaused then return
		@activeBugger?.continue()
	pause: ->
		if @ui.isPaused then return
		@activeBugger?.pause()

	stepIn: ->
		@activeBugger?.stepIn()
	stepOver: ->
		@activeBugger?.stepOver()
	stepOut: ->
		@activeBugger?.stepOut()

	addBreakpoint: (path, line) ->
		markers = []
		breakpoint =
			path: path
			line: line
			markers: markers
		@breakpoints.push breakpoint

		@activeBugger?.addBreakpoint breakpoint

		for editor in atom.workspace.getTextEditors()
			if editor.getPath() == path
				@installTextEditor editor
				gutter = editor.gutterWithName 'debug-gutter'
				marker = editor.markBufferRange [[line-1, 0], [line-1, 0]]
				gutter.decorateMarker marker,
					type: 'line-number'
					'class': 'debug-breakpoint'
				markers.push marker

	removeBreakpoint: (path, line) ->
		if @breakpoints.length>0
			editors = atom.workspace.getTextEditors()
			for i in [0..@breakpoints.length-1]
				breakpoint = @breakpoints[i]
				if breakpoint.path==path and breakpoint.line==line
					@breakpoints.splice i,1
					@activeBugger?.removeBreakpoint breakpoint
					i--
					for marker in breakpoint.markers
						marker.destroy()

	clearBreakpoints: ->
		oldBreakpoints = @breakpoints
		@breakpoints = []
		for breakpoint in oldBreakpoints
			for marker in breakpoint.markers
				marker.destroy()
			@activeBugger?.removeBreakpoint breakpoint

	hasBreakpoint: (path, line) ->
		for breakpoint in @breakpoints
			if breakpoint.path==path and breakpoint.line==line
				return true
		return false

	toggleBreakpoint: (path, line) ->
		if @breakpoints.length>0
			editors = atom.workspace.getTextEditors()
			for i in [0..@breakpoints.length-1]
				breakpoint = @breakpoints[i]
				if breakpoint.path==path and breakpoint.line==line
					@breakpoints.splice i,1
					@activeBugger?.removeBreakpoint breakpoint
					for marker in breakpoint.markers
						marker.destroy()
					return

		@addBreakpoint path, line

	getBreakpoints: ->
		return {path:breakpoint.path, line:breakpoint.line} for breakpoint in @breakpoints

	stop: ->
		if @activeBugger
			@activeBugger.stop()
			@activeBugger = null
			@ui.setStack []
			@ui.setVariables []
			@hide()
			@provider.emit 'stop'

	debugWithDebugger: (bugger, options) ->
		@stop()
		@ui.clear()
		@activeBugger = bugger
		@show()
		breakpointsCopy = ( {path:breakpoint.path, line:breakpoint.line} for breakpoint in @breakpoints )
		bugger.debug options,
			breakpoints: breakpointsCopy
			ui: @ui
		@provider.emit 'start'

	consumeDbgProvider: (debug) ->
		@buggers.push debug
		@customPanel.updateDebuggers()

	provideDbg: ->
		return @provider
