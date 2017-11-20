{CompositeDisposable} = require 'atom'
SidePane = require './SidePane'

toHtml = (input) ->
	return input
		.replace /</g,'&lt;'
		.replace />/g,'&gt;'
		.replace /\n/g,'<br />'

module.exports =
class VariableList extends SidePane
	getTitle: -> 'Variables'
	getDefaultLocation: -> 'right'

	constructor: (bugger) ->
		super

		@subscriptions = new CompositeDisposable()

		@bugger = bugger

		@showVariableTypes = false

		showToolbar = false

		@element = document.createElement 'div'
		@element.classList.add 'debug-sidebar'
		@element.classList.add 'with-toolbar' if showToolbar

		options = document.createElement 'div'
		options.classList.add 'options', 'btn-group', 'btn-toggle'

		@variableOptionTypes = document.createElement 'button'
		@variableOptionTypes.classList.add 'btn', 'btn-sm', 'icon', 'icon-info'
		@variableOptionTypes.title = 'Show variable types'
		@variableOptionTypes.addEventListener 'click', =>
			@setShowVariableTypes !@showVariableTypes

		@subscriptions.add atom.tooltips.add @variableOptionTypes,
			title: @variableOptionTypes.title
			placement: 'bottom'

		options.appendChild @variableOptionTypes

		if showToolbar
			toolbar = document.createElement 'div'
			toolbar.classList.add 'toolbar'
			@element.appendChild toolbar

			toolbar.appendChild options

			filter = document.createElement 'input'
			filter.type = 'search'
			filter.placeholder = 'Filter'
			filter.classList.add 'input-search'
			toolbar.appendChild filter

		body = document.createElement 'div'
		body.classList.add 'body'
		@element.appendChild body

		bodyInner = document.createElement 'div'
		bodyInner.classList.add 'inner'
		body.appendChild bodyInner

		if !toolbar
			@element.appendChild options

		@variableList = document.createElement 'ul'
		@variableList.classList.add 'list-tree', 'has-collapsable-children', 'variable-list'
		bodyInner.appendChild @variableList

		@expandedVariables = {}

		@isVisible = false

	dispose: ->
		@destroy()
		@subscriptions.dispose()

	setShowVariableTypes: (visible) ->
		@showVariableTypes = visible
		@variableOptionTypes.classList.toggle 'selected', visible
		@variableList.classList.toggle 'show-types', @showVariableTypes

	updateVariables: (variables) ->
		while @variableList.firstChild
			@variableList.removeChild @variableList.firstChild

		selectItem = (item) =>
			for sibling in @variableList.querySelectorAll '.selected'
				if sibling!=item then sibling.classList.remove 'selected'
			item.classList.add 'selected'

		addItem = (list, variable) =>
			stringName = variable.name
			stringType = if variable.type then ' (' + variable.type + ') ' else null
			stringValue = if variable.value then variable.value else null
			title = if stringName and (stringType or stringValue) then "<strong>#{toHtml stringName}</strong>" + (toHtml stringType) + (if stringValue then (if stringName then ': ' else '') + (toHtml stringValue) else '') else null

			listItem = null

			if variable.expandable
				tree = document.createElement 'li'
				tree.classList.add 'list-nested-item', 'collapsed'
				list.appendChild tree

				listItem = document.createElement 'div'
				listItem.classList.add 'list-item'
				listItem.addEventListener 'mousedown', -> selectItem tree
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

						@bugger.activeBugger?.getVariableChildren variable.fullName
							.then (children) =>
								branch.removeChild loaderItem
								for child in children
									if !child.fullName then child.fullName = variable.fullName+'.'+child.name
									addItem branch, child
							, =>
								branch.removeChild loaderItem

				tree.appendChild listItem

				branch = document.createElement 'ul'
				branch.classList.add 'list-tree'
				tree.appendChild branch
			else
				listItem = document.createElement 'li'
				listItem.classList.add 'list-item'
				listItem.addEventListener 'mousedown', -> selectItem listItem
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
				text.classList.add 'value', 'selectable'
				text.textContent = stringValue
				item.appendChild text

		for variable in variables
			if !variable.fullName then variable.fullName = variable.name
			addItem @variableList, variable
