{Emitter, CompositeDisposable} = require 'atom'

module.exports =
class Sidebar
	constructor: (bugger) ->
		@subscriptions = new CompositeDisposable()

		@emitter = new Emitter()
		@bugger = bugger

		@showSystemStack = false
		@showVariableTypes = false

		@element = document.createElement 'div'
		@element.classList.add 'debug-sidebar', 'padded'

		stackBlock = document.createElement 'div'
		stackBlock.classList.add 'inset-panel', 'stack'
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
		variableBlock.classList.add 'inset-panel', 'variables'
		@element.appendChild variableBlock

		variableHeading = document.createElement 'div'
		variableHeading.classList.add 'panel-heading'
		variableHeading.textContent = 'Variables'
		variableBlock.appendChild variableHeading

		variableOptions = document.createElement 'div'
		variableOptions.classList.add 'options', 'btn-group', 'btn-toggle'
		variableHeading.appendChild variableOptions

		@variableOptionTypes = document.createElement 'button'
		@variableOptionTypes.classList.add 'btn', 'btn-sm', 'icon', 'icon-info'
		@variableOptionTypes.title = 'Show variable types'
		@variableOptionTypes.addEventListener 'click', =>
			@setShowVariableTypes !@showVariableTypes

		@subscriptions.add atom.tooltips.add @variableOptionTypes,
      title: @variableOptionTypes.title
      placement: 'bottom'

		variableOptions.appendChild @variableOptionTypes

		variableBody = document.createElement 'div'
		variableBody.classList.add 'panel-body', 'padded'
		variableBlock.appendChild variableBody

		@variableList = document.createElement 'ul'
		@variableList.classList.add 'list-tree', 'has-collapsable-children', 'variable-list'
		variableBody.appendChild @variableList

		@expandedVariables = {}

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

			if frame.error
				listItem.classList.add 'text-error'

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

	setShowVariableTypes: (visible) ->
		@showVariableTypes = visible
		@variableOptionTypes.classList.toggle 'selected', visible
		@variableList.classList.toggle 'show-types', @showVariableTypes

	updateVariables: (variables) ->
		while @variableList.firstChild
			@variableList.removeChild @variableList.firstChild

		addItem = (list, name, variable) =>
			stringName = variable.name
			stringType = if variable.type then ' : ' + variable.type else ''
			stringValue = if variable.value then ' = ' + variable.value else ''
			title = if variable.type or variable.value then "<strong>#{stringName}</strong>" + stringType + (if variable.value then ' = ' + (variable.value.replace /\n/g,'<br />') else '') else null

			listItem = null

			if variable.expandable
				tree = document.createElement 'li'
				tree.classList.add 'list-nested-item', 'collapsed'
				list.appendChild tree

				listItem = document.createElement 'div'
				listItem.classList.add 'list-item'
				listItem.addEventListener 'click', =>
					tree.classList.toggle 'collapsed'
					if branch.childNodes.length<1
						@bugger.activeBugger?.getVariableChildren name
							.then (children) =>
								for child in children
									addItem branch, name+'.'+child.name, child

				tree.appendChild listItem

				branch = document.createElement 'ul'
				branch.classList.add 'list-tree'
				tree.appendChild branch
			else
				listItem = document.createElement 'li'
				listItem.classList.add 'list-item'
				list.appendChild listItem

			if title
				@subscriptions.add atom.tooltips.add listItem,
					html: true
					title: "<div class='debug-variable-tooltip'>#{title}</div>"
					placement: 'top'

			item = document.createElement 'span'
			listItem.appendChild item

			text = document.createElement 'strong'
			text.textContent = stringName
			item.appendChild text

			text = document.createElement 'span'
			text.classList.add 'type'
			text.textContent = stringType
			item.appendChild text

			text = document.createTextNode stringValue
			item.appendChild text

		for variable in variables
			addItem @variableList, variable.name, variable

	setFrame: (index) ->
		index = @stackList.childNodes.length-1-index #reverse it
		if @stackList.childNodes.length>0 then for i in [0..@stackList.childNodes.length-1]
			if i==index
				@stackList.childNodes[i].classList.add 'selected'
			else
				@stackList.childNodes[i].classList.remove 'selected'
