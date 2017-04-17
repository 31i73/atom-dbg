{Emitter} = require 'atom'
Pane = require './Pane'

module.exports =
class SidePane extends Pane
	constructor: ->
		super
		@isVisible = false

	destroy: ->
		super
		@isVisible = false
		@emitter.emit 'hidden'

	show: -> return new Promise (resolve) =>
		@isVisible = true
		split = atom.workspace.getRightDock().getPaneItems().length > 0
		(atom.workspace.open this, searchAllPanes:true, split:if split then 'down' else 'up').then =>
			@emitter.emit 'shown'
			resolve()

	hide: ->
		@destroy()

	toggle: ->
		if @isVisible then @hide() else @show()
