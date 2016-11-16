{Emitter, File} = require 'atom'

trimString = (string, length) ->
	if string.length<=length
		return string
	else
		return (string.substr 0, length/2-1) + '...' + (string.substr string.length - (length/2-2))

module.exports =
class Ui
	constructor: (bugger) ->
		@emitter = new Emitter
		@bugger = bugger

		@isPaused = false
		@isStepping = false
		@stack = []
		@currentPath = null
		@currentLine = 0
		@variables = []
		@lastVariables = {}
		@lastLines = {}
		@markers = []
		@openFiles = {}
		@hintMarkers = {}
		@showHints = true

		atom.workspace.observeTextEditors (editor) =>
			@addEditorMarkers editor

	serialize: ->

	clear: ->
		#TODO

	setLocation: (filename, lineNumber) ->
		if !filename then return

		file = new File filename

		file.exists()
			.then (exists) =>
				if exists
					atom.workspace.open filename,
						initialLine: lineNumber-1
						pending: true
						searchAllPanes: true
					.then (textEditor) =>
						@openFiles[filename] = textEditor
						textEditor.onDidDestroy =>
							delete @openFiles[filename]

	setStack: (stack) ->
		@stack = stack
		@bugger.sidebar.updateStackList @stack

		@clearEditorMarkers()
		for editor in atom.workspace.getTextEditors()
			@addEditorMarkers editor

		if stack.length>0
			@setFrame @stack.length - 1

	setVariables: (variables) ->
		@variables = variables

		if @currentPath
			lastVariables = @lastVariables[@currentPath]
			lastLine = @lastLines[@currentPath]
			if !lastVariables
				lastVariables = @lastVariables[@currentPath] = {}

			updateMessages = []

			for variable in variables
				if @isStepping
					old = lastVariables[variable.name]
					if variable.value && (!old || old.value!=variable.value)
						# updateMessages.push variable.name+' = '+variable.value
						updateMessages.push variable.name+' = '+trimString (variable.value.replace /\s*[\r\n]\s*/g, ' '), 48

				lastVariables[variable.name] = variable

			if @isStepping && updateMessages.length
				@setHint @currentPath, lastLine, updateMessages.join '\n'

		@bugger.sidebar.updateVariables @variables

	setFrame: (index) ->
		@bugger.sidebar.setFrame index
		frame = @stack[index]
		if !frame.local
			@bugger.sidebar.setShowSystemStack true

		if frame.file != @currentPath || frame.line != @currentLine
			@lastLines[@currentPath] = @currentLine

		@currentPath = frame.file
		@currentLine = frame.line

		@setLocation frame.file, frame.line

	clearEditorMarkers: ->
		for marker in @markers
			marker.destroy()
		@markers = []

	setHint: (filename, lineNumber, info) ->
		if !@showHints then return

		textEditor = @openFiles[filename]
		if !textEditor then return

		line = (textEditor.lineTextForBufferRow lineNumber-1)||''
		lineWidth = line.length
		lineIndent = textEditor.indentationForBufferRow lineNumber-1
		lineMarker = textEditor.markBufferRange [[lineNumber-1, lineIndent], [lineNumber-1, lineWidth]]

		markerObject =
			marker: lineMarker
			decoration: null
			element: null

		hash = filename+'-'+lineNumber
		@hintMarkers[hash]?.marker.destroy()
		@hintMarkers[hash] = markerObject

		if false
			markerObject.element = element = document.createElement 'div'
			element.classList.add 'debug-hint-overlay'
			element.classList.add 'inline'
			element.classList.toggle 'hidden', !@showHints

			for line in info.split '\n'
				element.append document.createElement 'br'
				element.append document.createTextNode line
			element.removeChild element.children[0]
			# element.textContent = info

			atom.config.observe 'editor.lineHeight', (h) ->
				element.style.top = -h+'em'
				element.style.height = h+'em'

			markerObject.decoration = textEditor.decorateMarker lineMarker,
				type: 'overlay'
				item: element

		else
			markerObject.element = element = document.createElement 'div'
			element.classList.add 'debug-hint-block'
			element.classList.toggle 'hidden', !@showHints

			indent = document.createElement 'div'
			indent.classList.add 'indent'
			atom.config.observe 'editor.tabLength', (w) ->
				indent.textContent = Array(w+1).join(' ');
			element.appendChild indent

			content = document.createElement 'div'
			content.classList.add 'content'
			for line in info.split '\n'
				content.appendChild document.createElement 'br'
				content.appendChild document.createTextNode line
			content.removeChild content.children[0]
			# element.textContent = info

			element.appendChild content

			markerObject.decoration = textEditor.decorateMarker lineMarker,
				type: 'block'
				position: 'after'
				item: element

	clearHints: ->
		for hash,marker of @hintMarkers
			marker.marker.destroy()
		@hintMarkers = {}

	clearAll: ->
		@currentPath = null
		@currentLine = 0
		@variables = []
		@lastVariables = {}
		@lastLines = {}
		@isPaused = false
		@isStepping = false
		@clearHints()
		@clearEditorMarkers()
		@setStack []
		@setVariables []

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
		@isStepping = false
		@bugger.stop()

	showWarning: (message) ->
		atom.notifications.addWarning message, {dismissable: true}

	showError: (message) ->
		atom.notifications.addError message, {dismissable: true}

	setShowHints: (set) ->
		@showHints = set
		@emitter.emit 'setShowHints', set
		if !set
			@clearHints()

		# for hash, marker of @hintMarkers
		# 	marker.element.classList.toggle 'hidden', !set
