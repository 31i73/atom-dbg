{SelectListView, $$} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
class ConfigList extends SelectListView
	initialize: (bugger) ->
		super
		@emitter = new Emitter
		@bugger = bugger

	viewForItem: (item) ->
		if item.description
			$$ -> @li 'class':'two-lines', =>
				@div 'class':'primary-line', item.name
				@div 'class':'secondary-line', item.description
		else
			$$ -> @li item.name

	getFilterKey: -> 'name'

	setConfigs: (configs) ->
		items = configs.slice()

		items.push name:'Custom', description:'Configure a custom debug session', callback: => @bugger.customDebug()
		items.push name:'Edit', description:'Edit your project debug settings', callback: => @bugger.openConfigFile()

		@setItems items

	cancel: ->
		@emitter.emit 'close'

	confirmed: (item) ->
		@emitter.emit 'close'

		if item.config
			@bugger.debug item.config
		else if item.callback
			item.callback()
