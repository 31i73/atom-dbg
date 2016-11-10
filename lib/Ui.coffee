{File} = require 'atom'

module.exports =
class Ui
	constructor: (bugger) ->
		@bugger = bugger
		@isPaused = false
		@stack = []
		@variables = []
		@markers = []

		atom.workspace.observeTextEditors (editor) =>
			@addEditorMarkers editor

	serialize: ->

	clear: ->
		#TODO

	setLocation: (filename, lineNumber) ->
		if !filename then return

		file = new File filename

		file.exists()
			.then (exists) ->
				if exists
					atom.workspace.open filename,
						initialLine: lineNumber-1
						pending: true
						searchAllPanes: true

	setStack: (stack) ->
		@stack = stack
		@bugger.sidebar.updateStackList @stack

		last_valid_frame = null

		for frame in @stack
			if frame.local
				last_valid_frame = frame

		if last_valid_frame!=null
			@setLocation last_valid_frame.file, last_valid_frame.line

		@clearEditorMarkers()
		for editor in atom.workspace.getTextEditors()
			@addEditorMarkers editor

		if stack.length>0
			@setFrame @stack.length - 1

	setVariables: (variables) ->
		@variables = variables
		@bugger.sidebar.updateVariables @variables

	setFrame: (index) ->
		@bugger.sidebar.setFrame index
		frame = @stack[index]
		if !frame.local
			@bugger.sidebar.setShowSystemStack true
		@setLocation frame.file, frame.line

	clearEditorMarkers: ->
		for marker in @markers
			marker.destroy()
		@markers = []

	addEditorMarkers: (textEditor) ->
		path = textEditor.getPath()
		for frame in @stack
			if frame.file == path
				@markers.push lineMarker = textEditor.markBufferRange [[frame.line-1, 0], [frame.line-1, 0]]
				_class = if frame.error then 'debug-position-error' else 'debug-position'
				textEditor.decorateMarker lineMarker,
					type: 'line-number'
					class: _class
				textEditor.decorateMarker lineMarker,
					type: 'line'
					class: _class

	running: ->
		@isPaused = false
		@setStack []
		@setVariables []
		@bugger.toolbar.updateButtons()
		# @bugger.atomSidebar.hide()

	paused: ->
		currentWindow = (require 'electron').remote.getCurrentWindow()
		currentWindow.focus();

		@isPaused = true
		@bugger.toolbar.updateButtons()
		@bugger.atomSidebar.show()

	stop: ->
		@bugger.stop()

	showWarning: (message) ->
		atom.notifications.addWarning message, {dismissable: true}

	showError: (message) ->
		atom.notifications.addError message, {dismissable: true}
