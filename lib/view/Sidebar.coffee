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

		stackListTable = document.createElement 'table'
		stackBody.appendChild stackListTable

		@stackListTBody = document.createElement 'tbody'
		stackListTable.appendChild @stackListTBody

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
		for element in @stackListTBody.childNodes
			if !(element.classList.contains 'local')
				element.style.display = if visible then '' else 'none'

	updateStackList: (stack) ->
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

	setShowVariableTypes: (visible) ->
		@showVariableTypes = visible
		@variableOptionTypes.classList.toggle 'selected', visible
		@variableList.classList.toggle 'show-types', @showVariableTypes

	updateVariables: (variables) ->
		while @variableList.firstChild
			@variableList.removeChild @variableList.firstChild

		addItem = (list, name, variable) =>
			stringName = variable.name
			stringType = if variable.type then ' (' + variable.type + ') ' else null
			stringValue = if variable.value then variable.value else null
			title = if stringName and (stringType or stringValue) then "<strong>#{stringName}</strong>" + stringType + (if stringValue then (if stringName then ': ' else '') + (stringValue.replace /\n/g,'<br />') else '') else null

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
						loaderItem = document.createElement 'li'
						loaderItem.classList.add 'list-item'
						branch.appendChild loaderItem

						# loader = document.createElement 'progress'
						# loader.classList.add 'inline-block', 'debug-fadein'
						# loaderItem.appendChild loader

						loader = document.createElement 'span'
						loader.classList.add 'loading', 'loading-spinner-tiny', 'inline-block', 'debug-fadein'
						loaderItem.appendChild loader

						@bugger.activeBugger?.getVariableChildren name
							.then (children) =>
								branch.removeChild loaderItem
								for child in children
									addItem branch, name+'.'+child.name, child
							, =>
								branch.removeChild loaderItem

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

			item = document.createElement 'code'
			listItem.appendChild item

			text = document.createElement 'span'
			text.classList.add 'identifier'
			text.textContent = stringName
			item.appendChild text

			text = document.createElement 'span'
			text.classList.add 'type'
			text.textContent = stringType
			item.appendChild text

			if stringValue != null
				if stringName
					text = document.createTextNode ': '
					item.appendChild text

				text = document.createElement if stringName then 'span' else 'em'
				text.classList.add 'value'
				text.textContent = stringValue
				item.appendChild text

		for variable in variables
			addItem @variableList, variable.name, variable

	setFrame: (index) ->
		index = @stackListTBody.childNodes.length-1-index #reverse it
		if @stackListTBody.childNodes.length>0 then for i in [0..@stackListTBody.childNodes.length-1]
			if i==index
				@stackListTBody.childNodes[i].classList.add 'selected'
			else
				@stackListTBody.childNodes[i].classList.remove 'selected'
