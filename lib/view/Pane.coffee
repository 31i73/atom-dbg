{Emitter, CompositeDisposable} = require 'atom'

module.exports =
class Pane
	constructor: ->
		@emitter = new Emitter()

	destroy: ->
		@emitter.emit 'did-destroy'

	onDidDestroy: (callback) ->
		@emitter.on 'did-destroy', callback
