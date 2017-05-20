{CompositeDisposable} = require 'atom'
SidePane = require './SidePane'

module.exports =
class BreakpointList extends SidePane
	getTitle: -> 'Breakpoints'
	getDefaultLocation: -> 'right'

	constructor: (bugger) ->
		super

		@subscriptions = new CompositeDisposable()

		@bugger = bugger

		@showSystemStack = false

		showToolbar = false

		@element = document.createElement 'div'
		@element.classList.add 'debug-sidebar', 'debug-sidebar-breakpoints'
		@element.classList.add 'with-toolbar' if showToolbar

		@subscriptions.add atom.commands.add @element, 'dbg:remove-breakpoint': =>
			if selectedRow = @tableBody.querySelector 'tr.selected'
				@bugger.removeBreakpoint selectedRow.dataset.path, parseInt selectedRow.dataset.line

		if showToolbar
			toolbar = document.createElement 'div'
			toolbar.classList.add 'toolbar'
			@element.appendChild toolbar

			filter = document.createElement 'input'
			filter.type = 'search'
			filter.placeholder = 'Filter'
			filter.classList.add 'input-search'
			toolbar.appendChild filter

		body = document.createElement 'div'
		body.classList.add 'body'
		@element.appendChild body

		@table = document.createElement 'table'
		body.appendChild @table

		@tableHead = document.createElement 'thead'
		@table.appendChild @tableHead

		row = document.createElement 'tr'
		@tableHead.appendChild row

		col = document.createElement 'th'
		col.textContent = 'Filename'
		row.appendChild col

		col = document.createElement 'th'
		col.textContent = 'Line'
		col.style.textAlign = 'right'
		row.appendChild col

		@tableBody = document.createElement 'tbody'
		@table.appendChild @tableBody

	dispose: ->
		@destroy()
		@subscriptions.dispose()

	updateBreakpoints: (breakpoints) ->
		while @tableBody.firstChild
			@tableBody.removeChild @tableBody.firstChild

		rows = []

		selectRow = (row) ->
			for sibling in rows
				if sibling != row then sibling.classList.remove 'selected'
			row.classList.add 'selected'

		gotoBreakpoint = (row, breakpoint, permanent) ->
			selectRow row
			atom.workspace.open breakpoint.path, pending: !permanent, activatePane: permanent, searchAllPanes: true, initialLine:breakpoint.line-1

		for breakpoint in breakpoints
			row = document.createElement 'tr'
			row.dataset.path = breakpoint.path
			row.dataset.line = breakpoint.line
			rows.push row
			@tableBody.appendChild row

			do (row, breakpoint) ->
				row.addEventListener 'mousedown', => selectRow row
				row.addEventListener 'click', => gotoBreakpoint row, breakpoint, false
				row.addEventListener 'dblclick', => gotoBreakpoint row, breakpoint, true

			path = atom.project.relativizePath breakpoint.path

			col = document.createElement 'td'
			row.appendChild col

			text = document.createElement 'span'
			text.textContent = path[1]
			col.appendChild text

			col = document.createElement 'td'
			col.style.textAlign = 'right'
			row.appendChild col

			text = document.createElement 'span'
			text.textContent = breakpoint.line
			col.appendChild text

		@table.style.display = if @tableBody.children.length==0 then 'none' else ''
