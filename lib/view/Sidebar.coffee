{Emitter, CompositeDisposable} = require 'atom'

module.exports =
class Sidebar
	constructor: (bugger) ->
		@subscriptions = new CompositeDisposable()

		@emitter = new Emitter()
		@bugger = bugger

		@showSystemStack = false

		@element = document.createElement 'div'
		@element.classList.add 'debug-sidebar', 'padded'

		stackBlock = document.createElement 'div'
		stackBlock.classList.add 'inset-panel'
		@element.appendChild stackBlock

		stackHeading = document.createElement 'div'
		stackHeading.classList.add 'panel-heading'
		stackHeading.textContent = 'Call Stack'
		stackBlock.appendChild stackHeading

		stackOptions = document.createElement 'div'
		stackOptions.classList.add 'options', 'btn-group', 'btn-toggle'
		stackHeading.appendChild stackOptions

		@stackOptionSystem = document.createElement 'button'
		@stackOptionSystem.classList.add 'btn', 'btn-sm', 'icon', 'icon-circuit-board'
		@stackOptionSystem.title = 'Show system paths'
		@stackOptionSystem.addEventListener 'click', =>
			@setShowSystemStack !@showSystemStack

		@subscriptions.add atom.tooltips.add @stackOptionSystem,
      title: @stackOptionSystem.title
      placement: 'bottom'

		stackOptions.appendChild @stackOptionSystem

		stackBody = document.createElement 'div'
		stackBody.classList.add 'panel-body', 'padded'
		stackBlock.appendChild stackBody

		@stackList = document.createElement 'ul'
		@stackList.classList.add 'list-group'
		stackBody.appendChild @stackList

		variableBlock = document.createElement 'div'
		variableBlock.classList.add 'inset-panel'
		@element.appendChild variableBlock

		variableHeading = document.createElement 'div'
		variableHeading.classList.add 'panel-heading'
		variableHeading.textContent = 'Variables'
		variableBlock.appendChild variableHeading

		variableBody = document.createElement 'div'
		variableBody.classList.add 'panel-body', 'padded'
		variableBlock.appendChild variableBody

		@variableList = document.createElement 'ul'
		@variableList.classList.add 'list-group'
		variableBody.appendChild @variableList

	destroy: ->
		@subscriptions.dispose()
		@element.remove()

	getElement: ->
		@element

	setShowSystemStack: (visible) ->
		@showSystemStack = visible
		@stackOptionSystem.classList.toggle 'selected', visible
		for element in @stackList.childNodes
			if !(element.classList.contains 'local')
				element.style.display = if visible then '' else 'none'

	updateStackList: (stack) ->
		while @stackList.firstChild
			@stackList.removeChild @stackList.firstChild

		if stack.length>0 then for i in [0..stack.length-1]
			frame = stack[i]
			listItem = document.createElement 'li'
			listItem.classList.add 'list-item'
			if frame.local
				listItem.classList.add 'local'
			else
				if !@showSystemStack
					listItem.style.display = 'none'

			do (i) =>
				listItem.addEventListener 'click', => @bugger.activeBugger?.selectFrame i
			@stackList.insertBefore listItem, @stackList.firstChild

			item = document.createElement 'span'
			item.setAttribute 'title', frame.name + ' - ' + frame.path
			if frame.local
				item.classList.add 'icon', 'icon-file-text'
			else
				item.classList.add 'no-icon'
			listItem.appendChild item

			text = document.createElement 'strong'
			text.textContent = frame.name
			item.appendChild text

			text = document.createTextNode ' ' + frame.path + (if frame.line then ':'+frame.line else '')
			item.appendChild text

	updateVariables: (variables) ->
		while @variableList.firstChild
			@variableList.removeChild @variableList.firstChild

		for variable in variables
			stringName = variable.name
			stringType = if variable.type then ' : ' + variable.type else ''
			stringValue = if variable.value then ' = ' + variable.value else ''

			listItem = document.createElement 'li'
			listItem.classList.add 'list-item'
			listItem.setAttribute 'title', stringName + stringType + stringValue
			@variableList.appendChild listItem

			item = document.createElement 'span'
			listItem.appendChild item

			text = document.createElement 'strong'
			text.textContent = stringName
			item.appendChild text

			text = document.createTextNode stringType + stringValue
			item.appendChild text

	setFrame: (index) ->
		index = @stackList.childNodes.length-1-index #reverse it
		if @stackList.childNodes.length>0 then for i in [0..@stackList.childNodes.length-1]
			if i==index
				@stackList.childNodes[i].classList.add 'selected'
			else
				@stackList.childNodes[i].classList.remove 'selected'
