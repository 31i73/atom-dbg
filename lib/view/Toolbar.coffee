{CompositeDisposable, Emitter} = require 'atom'

module.exports =
class Toolbar
	constructor: (bugger) ->
		@subscriptions = new CompositeDisposable()
		@emitter = new Emitter()
		@bugger = bugger

		@element = document.createElement 'div'
		@element.classList.add 'debug-toolbar', 'tool-panel'

		@showHints = true

		svg = document.createElement 'div'
		svg.innerHTML =
			'''
			<svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" version="1.1" style="display:none">
				<symbol id="debug-symbol-step-over" viewbox="0 0 17 19">
					<circle cx="8" cy="6" r="3"></circle>
					<polygon points="17,14 12,9 12,19"></polygon>
					<rect x="0" y="12" width="13" height="4"></rect>
				</symbol>
				<symbol id="debug-symbol-step-in" viewBox="0 0 17 19">
					<circle cx="9" cy="5" r="3"></circle>
					<polygon points="9,10 14,15 4,15"></polygon>
					<rect x="7" y="15" width="4" height="6"></rect>
				</symbol>
				<symbol id="debug-symbol-step-out" viewBox="0 0 17 19">
					<circle cx="9" cy="5" r="3"></circle>
					<polygon points="9,19 14,14 4,14"></polygon>
					<rect x="7" y="10" width="4" height="6"></rect>
				</symbol>
			</svg>
			'''
		@element.appendChild svg

		createSvgIcon = (iconName) ->
			svgNamespace= 'http://www.w3.org/2000/svg'
			xlinkNamespace= 'http://www.w3.org/1999/xlink'
			xmlnsNamespace= 'http://www.w3.org/2000/xmlns/'

			icon = document.createElementNS svgNamespace, 'svg'
			icon.setAttributeNS 'http://www.w3.org/2000/xmlns/', 'xmlns', svgNamespace
			icon.setAttributeNS 'http://www.w3.org/2000/xmlns/', 'xmlns', 'xmlns:xlink', xlinkNamespace
			icon.classList.add 'icon'

			iconUse = document.createElementNS svgNamespace, 'use'
			iconUse.setAttributeNS xlinkNamespace, 'xlink:href', '#'+iconName
			icon.appendChild iconUse

			return icon

		@options = document.createElement 'div'
		@options.classList.add 'options'
		@element.appendChild @options

		buttonToolbar = document.createElement 'div'
		buttonToolbar.classList.add 'btn-toolbar'
		@element.appendChild buttonToolbar

		optionGroup = document.createElement 'div'
		optionGroup.classList.add 'btn-group'
		optionGroup.classList.add 'options'
		buttonToolbar.appendChild optionGroup

		@buttonHints = document.createElement 'button'
		@buttonHints.classList.add 'btn', 'icon', 'icon-comment', 'selected'
		@buttonHints.addEventListener 'click', =>
			@bugger.ui.setShowHints !@bugger.ui.showHints
		@subscriptions.add atom.tooltips.add @buttonHints, title: 'Show inline hints'
		optionGroup.appendChild @buttonHints

		@bugger.ui.emitter.on 'setShowHints', (set) =>
			@buttonHints.classList.toggle 'selected', set

		optionGroup = document.createElement 'div'
		optionGroup.classList.add 'btn-group'
		optionGroup.classList.add 'options'
		buttonToolbar.appendChild optionGroup

		@buttonToggleStack = document.createElement 'button'
		@buttonToggleStack.classList.add 'btn', 'icon', 'icon-steps'
		@buttonToggleStack.addEventListener 'click', => @bugger.stackList.toggle()
		@bugger.stackList.emitter.on 'shown', => @buttonToggleStack.classList.add 'selected'
		@bugger.stackList.emitter.on 'hidden', => @buttonToggleStack.classList.remove 'selected'
		@subscriptions.add atom.tooltips.add @buttonToggleStack, title: 'Show stack list'
		optionGroup.appendChild @buttonToggleStack

		@buttonToggleVariables = document.createElement 'button'
		@buttonToggleVariables.classList.add 'btn', 'icon', 'icon-list-unordered'
		@buttonToggleVariables.addEventListener 'click', => @bugger.variableList.toggle()
		@bugger.variableList.emitter.on 'shown', => @buttonToggleVariables.classList.add 'selected'
		@bugger.variableList.emitter.on 'hidden', => @buttonToggleVariables.classList.remove 'selected'
		@subscriptions.add atom.tooltips.add @buttonToggleVariables, title: 'Show variables'
		optionGroup.appendChild @buttonToggleVariables

		@buttonToggleBreakpoints = document.createElement 'button'
		@buttonToggleBreakpoints.classList.add 'btn', 'icon', 'icon-stop'
		@buttonToggleBreakpoints.addEventListener 'click', => @bugger.breakpointList.toggle()
		@bugger.breakpointList.emitter.on 'shown', => @buttonToggleBreakpoints.classList.add 'selected'
		@bugger.breakpointList.emitter.on 'hidden', => @buttonToggleBreakpoints.classList.remove 'selected'
		@subscriptions.add atom.tooltips.add @buttonToggleBreakpoints, title: 'Show breakpoints'
		optionGroup.appendChild @buttonToggleBreakpoints

		buttonGroup = document.createElement 'div'
		buttonGroup.classList.add 'btn-group'
		buttonToolbar.appendChild buttonGroup

		@buttonPlay = document.createElement 'button'
		@buttonPlay.classList.add 'btn', 'icon', 'icon-playback-play'
		@buttonPlay.addEventListener 'click', -> bugger.continue()
		@subscriptions.add atom.tooltips.add @buttonPlay, title: 'Continue'
		buttonGroup.appendChild @buttonPlay

		@buttonPause = document.createElement 'button'
		@buttonPause.classList.add 'btn', 'icon', 'icon-playback-pause'
		@buttonPause.addEventListener 'click', -> bugger.pause()
		@subscriptions.add atom.tooltips.add @buttonPause, title: 'Pause'
		buttonGroup.appendChild @buttonPause

		@buttonStop = document.createElement 'button'
		@buttonStop.classList.add 'btn', 'icon', 'icon-primitive-square'
		@buttonStop.addEventListener 'click', -> bugger.stop()
		@subscriptions.add atom.tooltips.add @buttonStop, title: 'Stop debugging'
		buttonGroup.appendChild @buttonStop

		buttonGroup = document.createElement 'div'
		buttonGroup.classList.add 'btn-group'
		buttonToolbar.appendChild buttonGroup

		@buttonStepOver = document.createElement 'button'
		@buttonStepOver.classList.add 'btn'
		@buttonStepOver.addEventListener 'click', -> bugger.stepOver()
		@buttonStepOver.appendChild createSvgIcon 'debug-symbol-step-over'
		@subscriptions.add atom.tooltips.add @buttonStepOver, title: 'Step over'
		buttonGroup.appendChild @buttonStepOver

		@buttonStepIn = document.createElement 'button'
		@buttonStepIn.classList.add 'btn'
		@buttonStepIn.addEventListener 'click', -> bugger.stepIn()
		@buttonStepIn.appendChild createSvgIcon 'debug-symbol-step-in'
		@subscriptions.add atom.tooltips.add @buttonStepIn, title: 'Step into'
		buttonGroup.appendChild @buttonStepIn

		@buttonStepOut = document.createElement 'button'
		@buttonStepOut.classList.add 'btn',
		@buttonStepOut.addEventListener 'click', -> bugger.stepOut()
		@buttonStepOut.appendChild createSvgIcon 'debug-symbol-step-out'
		@subscriptions.add atom.tooltips.add @buttonStepOut, title: 'Step out'
		buttonGroup.appendChild @buttonStepOut

		@updateButtons()

	destroy: ->
		@subscriptions.dispose()
		@element.remove()

	updateButtons: ->
		if @bugger.ui.isPaused
			@buttonPlay.classList.remove 'selected'
			@buttonPause.classList.add 'selected'
			@buttonStepIn.disabled = false
			@buttonStepOver.disabled = false
			@buttonStepOut.disabled = @bugger.ui.currentFrame < 1
		else
			@buttonPlay.classList.add 'selected'
			@buttonPause.classList.remove 'selected'
			@buttonStepIn.disabled = true
			@buttonStepOver.disabled = true
			@buttonStepOut.disabled = true

	getElement: ->
		@element
