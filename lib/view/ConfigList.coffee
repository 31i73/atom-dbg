SelectListView = require 'atom-select-list'
{Emitter} = require 'atom'

module.exports =
class ConfigList
	constructor: (bugger) ->
		@emitter = new Emitter
		@bugger = bugger
		@selectListView = new SelectListView
			items: []
			filterKeyForItems: (item) => item.nameb
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
				@emitter.emit 'close'
				if item.config
					@bugger.debug item.config
				else if item.callback
					item.callback()
			didCancelSelection: =>
				@emitter.emit 'close'

	destroy: ->
		@selectListView.destroy()

	setConfigs: (configs) ->
		items = configs.slice()

		items.push name:'Custom', description:'Configure a custom debug session', callback: => @bugger.customDebug()
		items.push name:'Edit', description:'Edit your project debug settings', callback: => @bugger.openConfigFile()

		@selectListView.update items: items
