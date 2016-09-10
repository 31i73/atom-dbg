Ui = require './Ui'
Toolbar = require './view/Toolbar'
Sidebar = require './view/Sidebar'

{CompositeDisposable, Emitter} = require 'atom'

module.exports = Debug =
	provider: null
	ui: null
	toolbar: null
	atomToolbar: null
	sidebar: null
	atomSidebar: null
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

		@disposable = new CompositeDisposable
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:stop': => @stop()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:continue': => @continue()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:pause': => @pause()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:pause-continue': => if @ui.isPaused then @continue() else @pause()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:stepIn': => @stepIn()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:stepOver': => @stepOver()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:stepOut': => @stepOut()
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:toggle-breakpoint': =>
			textEditor = atom.workspace.getActiveTextEditor()
			if textEditor!=null
				pos = textEditor.getCursorBufferPosition()
				@toggleBreakpoint textEditor.getPath(), pos.row+1
		@disposable.add atom.commands.add 'atom-workspace', 'dbg:clear-breakpoints': =>
			@clearBreakpoints()

		@disposable.add atom.workspace.observeTextEditors (textEditor) =>
			path = textEditor.getPath()

			gutter = null
			getGutter = () ->
				if !gutter
					gutter = textEditor.addGutter
						name: 'debug-gutter'
						priority: -200
						visible: true
				return gutter

			for breakpoint in @breakpoints
				if breakpoint.path == path
					marker = textEditor.markBufferRange [[breakpoint.line-1, 0], [breakpoint.line-1, 0]]
					getGutter().decorateMarker marker,
						type: 'line-number'
						'class': 'debug-breakpoint'

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

	continue: ->
		@activeBugger?.continue()
	pause: ->
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
				gutter = editor.gutterWithName 'debug-gutter'
				if !gutter
					gutter = editor.addGutter
						name: 'debug-gutter'
						priority: -200
						visible: true
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
		bugger.debug options,
			breakpoints: return {path:breakpoint.path, line:breakpoint.line} for breakpoint in @breakpoints
			ui: @ui
		@provider.emit 'start'

	consumeDbgProvider: (debug) ->
		@buggers.push debug

	provideDbg: ->
		return @provider
