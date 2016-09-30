path = require('path');
{CompositeDisposable} = require 'atom'

module.exports =
class CustomDebugView
  panel = null
  bugger = null
  
  constructor: (bugger) ->
    @subscriptions = new CompositeDisposable()
    @bugger = bugger
    
    @content()
    @handleEvents()
    
  handleEvents: ->
    # @subscriptions.add atom.commands.add @element,
    #   'core:close': => @panel?hide()
    #   'core:cancel': => @panel?hide()
    
  content: ->
    # Create root element
    @element = document.createElement('div')
    @element.setAttribute("tabIndex", -1)
    @element.classList.add('debug-custom')
    
    header = document.createElement('header')
    header.classList.add 'header'
    span = document.createElement('span')
    span.classList.add 'header-item', 'description'
    span.textContent = "Configure Debug Session"
    @element.appendChild header
    header.appendChild span
    
    @closeBtn = document.createElement('span')
    @closeBtn.classList.add 'header-item','pull-right','btn', 'icon', 'icon-remove-close'
    span.appendChild @closeBtn
      # @span 'Finding with Options: '
      # @span outlet: 'optionsLabel', class: 'options'
    # @subscriptions.add atom.tooltips.add @closeBtn, title: 'Choose File to Debug'
    @closeBtn.addEventListener 'click', => @panel?.hide()
    
    # debugger - Optional. The name of the dbg provider to use. (This can be omitted to auto-detect)
    # path - Optional. The path to the file to debug
    # args - Optional. An array of arguments to pass to the file being debugged
    # cwd - Optional. The working directory to use when debugging
    # ... - Optional. Custom debugger arguments
    
    div = document.createElement('div')
    span = document.createElement('span')
    label = document.createElement('label')
    # label.classList.add 'header-item'
    label.textContent = "Select Debugger"
    span.appendChild label
    div.appendChild span
    
    @selectDebugger = document.createElement('select')
    @selectDebugger.classList.add 'input-select'
    @element.appendChild div
    div.appendChild span
    span.appendChild @selectDebugger
    
    option = document.createElement('option')
    option.textContent = "auto"
    @selectDebugger.appendChild option
  
    # file to Debug
    section = document.createElement 'section'
    section.classList.add 'input-block'
    fileGroup = document.createElement 'div'
    fileGroup.classList.add 'input-block-item', 'input-block-item--flex', 'editor-container'
    @element.appendChild section
    section.appendChild fileGroup

    @pathInput = document.createElement 'atom-text-editor'
    @pathInput.setAttribute(name, value) for name, value of {"mini": true, "placeholder-text": "Path to the file to debug"}
    @pathInput.type = "text"
    fileGroup.appendChild @pathInput

    div = document.createElement 'div'
    div.classList.add 'input-block-item'
    bgroup = document.createElement 'div'
    bgroup.classList.add 'btn-group'
    @pathButton = document.createElement 'button'
    @pathButton.classList.add 'btn', 'icon', 'icon-file-binary'
    @pathButton.textContent = "Choose File"
    @pathButton.addEventListener 'click', => @pickFile()
    # @subscriptions.add atom.tooltips.add @pathButton, title: 'Choose File to Debug'
    section.appendChild div
    div.appendChild bgroup
    bgroup.appendChild @pathButton

    # file args
    section = document.createElement 'section'
    section.classList.add 'input-block'
    argsGroup = document.createElement 'div'
    argsGroup.classList.add 'input-block-item', 'input-block-item--flex', 'editor-container'
    @element.appendChild section
    section.appendChild argsGroup

    @argsInput = document.createElement 'atom-text-editor'
    @argsInput.setAttribute(name, value) for name, value of {"mini": true, "placeholder-text": "Arguments to pass to the file being debugged"}
    @argsInput.type = "text"
    argsGroup.appendChild @argsInput

    # working directory for debugger
    section = document.createElement 'section'
    section.classList.add 'input-block'
    cwdGroup = document.createElement 'div'
    cwdGroup.classList.add 'input-block-item', 'input-block-item--flex', 'editor-container'
    @element.appendChild section
    section.appendChild cwdGroup

    @cwdInput = document.createElement 'atom-text-editor'
    @cwdInput.setAttribute(name, value) for name, value of {"mini": true, "placeholder-text": "Working directory to use when debugging"}
    @cwdInput.type = "text"
    cwdGroup.appendChild @cwdInput

    div = document.createElement 'div'
    div.classList.add 'input-block-item'
    bgroup = document.createElement 'div'
    bgroup.classList.add 'btn-group'
    @cwdButton = document.createElement 'button'
    @cwdButton.classList.add 'btn', 'icon', 'icon-file-directory'
    @cwdButton.textContent = "Choose Directory"
    # @cwdButton.addEventListener 'click', -> bugger.continue()
    # @subscriptions.add atom.tooltips.add @cwdButton, title: 'Choose File to Debug'
    section.appendChild div
    div.appendChild bgroup
    bgroup.appendChild @cwdButton
    
    # Start Button
    startGroup = document.createElement 'div'
    startGroup.classList.add 'block'
    @element.appendChild startGroup
    
    @startButton = document.createElement 'button'
    @startButton.classList.add 'btn-lg', 'btn-success', 'icon', 'icon-chevron-right'
    @startButton.textContent = "Start"
    # @startButton.addEventListener 'click', -> bugger.continue()
    # @subscriptions.add atom.tooltips.add @startButton, title: 'Choose working directory'
    startGroup.appendChild @startButton

  pickFile: ->
    picker = document.createElement 'input'
    picker.setAttribute 'type', 'file'
    picker.onchange = () => 
      if picker.files.length > 0
        @pathInput.getModel().setBuffer(picker.files[0].path)
        if @cwdInput.getModel().getBuffer() == ""
          @cwdInput.getModel().setText(path.dirname(picker.files[0].path))
    picker.click()
    
  addDebuggerOption: (name) ->
    option = document.createElement('option')
    option.textContent = name
    @selectDebugger.appendChild option
              
  setPanel: (@panel) ->

  setBuggers: (@buggers) ->
    
  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @subscriptions.dispose()
    @element.remove()

  getElement: ->
    @element
