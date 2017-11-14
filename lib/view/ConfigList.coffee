SelectListView = require 'atom-select-list'

module.exports =
class ConfigList
	constructor: (bugger) ->
		@bugger = bugger
		@selectListView = new SelectListView
			items: []
			filterKeyForItem: (item) => item.name
			elementForItem: (item) =>
				element = document.createElement 'li'
				if item.description
					element.classList.add 'two-lines'
					div = document.createElement 'div'
					div.classList.add 'primary-line'
					div.textContent = item.name
					element.appendChild div
					div = document.createElement 'div'
					div.classList.add 'secondary-line'
					div.textContent = item.description
					element.appendChild div
				else
					element.textContent = item.name
				return element
			didConfirmSelection: (item) =>
				@hide()
				if item.config
					@bugger.debug item.config
				else if item.callback
					item.callback()
			didCancelSelection: => @hide()
		@modelPanel = atom.workspace.addModalPanel item: @selectListView, visible: false

	destroy: ->
		@selectListView.destroy()
		@modelPanel.destroy()

	setConfigs: (configs) ->
		items = configs.slice()

		items.push name:'Custom', description:'Configure a custom debug session', callback: => @bugger.customDebug()
		items.push name:'Edit', description:'Edit your project debug settings', callback: => @bugger.openConfigFile()

		@selectListView.update items: items

	hide: -> @modelPanel.hide()

	show: ->
		@modelPanel.show()
		@selectListView.reset()
		@selectListView.focus()
