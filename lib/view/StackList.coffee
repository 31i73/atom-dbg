{CompositeDisposable} = require 'atom'
SidePane = require './SidePane'

module.exports =
class StackList extends SidePane
	getTitle: -> 'Call Stack'
	getDefaultLocation: -> 'right'

	constructor: (bugger) ->
		super

		@subscriptions = new CompositeDisposable()

		@bugger = bugger

		@showSystemStack = false

		showToolbar = false

		@element = document.createElement 'div'
		@element.classList.add 'debug-sidebar'
		@element.classList.add 'with-toolbar' if showToolbar

		options = document.createElement 'div'
		options.classList.add 'options', 'btn-group', 'btn-toggle'

		@optionSystem = document.createElement 'button'
		@optionSystem.classList.add 'btn', 'btn-sm', 'icon', 'icon-circuit-board'
		@optionSystem.title = 'Show system paths'
		@optionSystem.addEventListener 'click', =>
			@setShowSystemStack !@showSystemStack

		@subscriptions.add atom.tooltips.add @optionSystem,
			title: @optionSystem.title
			placement: 'bottom'

		options.appendChild @optionSystem

		if showToolbar
			toolbar = document.createElement 'div'
			toolbar.classList.add 'toolbar'
			@element.appendChild toolbar

			toolbar.appendChild options

			# filter = document.createElement 'input'
			# filter.type = 'search'
			# filter.placeholder = 'Filter'
			# filter.classList.add 'input-search'
			# toolbar.appendChild filter

			spacer = document.createElement 'div'
			spacer.classList.add 'spacer'
			toolbar.appendChild spacer

			@threadSelector = document.createElement 'select'
			@threadSelector.classList.add 'input-select'
			toolbar.appendChild @threadSelector

			option = document.createElement 'option'
			option.textContent = 'thread name'
			@threadSelector.appendChild option

		body = document.createElement 'div'
		body.classList.add 'body'
		@element.appendChild body

		if !toolbar
			@element.appendChild options

		stackListTable = document.createElement 'table'
		body.appendChild stackListTable

		@stackListTBody = document.createElement 'tbody'
		stackListTable.appendChild @stackListTBody

	dispose: ->
		@destroy()
		@subscriptions.dispose()

	setShowSystemStack: (visible) ->
		@showSystemStack = visible
		@optionSystem.classList.toggle 'selected', visible
		for element in @stackListTBody.childNodes
			if !(element.classList.contains 'local')
				element.style.display = if visible then '' else 'none'

	updateStack: (stack) ->
		while @stackListTBody.firstChild
			@stackListTBody.removeChild @stackListTBody.firstChild

		if stack.length>0 then for i in [0..stack.length-1]
			frame = stack[i]

			listRow = document.createElement 'tr'
			if frame.error
				listRow.classList.add 'text-error'

			if frame.local
				listRow.classList.add 'local'
			else
				if !@showSystemStack
					listRow.style.display = 'none'

			do (i) =>
				listRow.addEventListener 'click', => @bugger.activeBugger?.selectFrame i
			@stackListTBody.insertBefore listRow, @stackListTBody.firstChild

			listRow.setAttribute 'title', frame.name + ' - ' + frame.path + (if frame.line then ':'+frame.line else '')

			cellLocation = document.createElement 'td'
			listRow.appendChild cellLocation

			text = document.createElement 'code'
			text.classList.add 'identifier'
			text.textContent = frame.name
			cellLocation.appendChild text

			cellPath = document.createElement 'td'
			listRow.appendChild cellPath

			path = document.createElement 'span'
			path.classList.add 'path'
			cellPath.appendChild path

			icon = document.createElement 'span'
			if frame.local
				icon.classList.add 'icon', 'icon-file-text'
			else
				icon.classList.add 'no-icon'
			path.appendChild icon

			text = document.createElement 'span'
			text.classList.add 'filepath'
			text.textContent = frame.path + (if frame.line then ':'+frame.line else '')
			path.appendChild text

	setFrame: (index) ->
		index = @stackListTBody.childNodes.length-1-index #reverse it
		if @stackListTBody.childNodes.length>0 then for i in [0..@stackListTBody.childNodes.length-1]
			if i==index
				@stackListTBody.childNodes[i].classList.add 'selected'
			else
				@stackListTBody.childNodes[i].classList.remove 'selected'
