{SelectListView, $$} = require 'atom-space-pen-views'
{Emitter} = require 'atom'

module.exports =
class ConfigList extends SelectListView
	initialize: () ->
		super
		@emitter = new Emitter()
		@configs = {}

	viewForItem: (item) ->
		$$ -> @li(item)

	setConfigs: (@configs) ->
		configNames = []
		configNames.push name for name of @configs
		@setItems configNames

	awaitSelection: ->
		return new Promise (resolve, reject) =>
			@resolveFunction = resolve

	cancel: ->
		@emitter.emit 'close'

	confirmed: (item) ->
		@emitter.emit 'close'
		@resolveFunction @configs[item] if @resolveFunction?
