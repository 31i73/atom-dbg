path = require('path');
{Emitter, promptForPath} = require 'atom'

module.exports =
class CustomDebugView
  bugger = null

  constructor: (bugger) ->
    @emitter = new Emitter()
    @bugger = bugger
    @content()

  content: ->
    # Create root element
    @element = document.createElement 'div'
    @element.setAttribute("tabIndex", -1)
    @element.classList.add('debug-custom')

    header = document.createElement 'div' 
    header.classList.add 'panel-heading'
    header.textContent = "Configure Debug Session"
    @element.appendChild header

    closeButton = document.createElement 'button'
    closeButton.classList.add 'btn', 'action-close', 'icon', 'icon-remove-close'
    header.appendChild closeButton

    closeButton.addEventListener 'click', =>
      @emitter.emit 'close'

    div = document.createElement('div')
    div.classList.add 'input-block-item', 'input-block-item--flex'
    span = document.createElement('span')
    label = document.createElement('label')
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
    pathButton = document.createElement 'button'
    pathButton.classList.add 'btn', 'icon', 'icon-file-binary'
    pathButton.textContent = "Choose File"
    pathButton.addEventListener 'click', => @pickFile()
    section.appendChild div
    div.appendChild bgroup
    bgroup.appendChild pathButton

    # file args
    section = document.createElement 'section'
    section.classList.add 'input-block'
    argsGroup = document.createElement 'div'
    argsGroup.classList.add 'input-block-item', 'input-block-item--flex', 'editor-container'
    @element.appendChild section
    section.appendChild argsGroup

    @argsInput = document.createElement 'atom-text-editor'
    @argsInput.setAttribute(name, value) for name, value of {"mini": true, "placeholder-text": "Optional: Arguments to pass to the file being debugged"}
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
    @cwdInput.setAttribute(name, value) for name, value of {"mini": true, "placeholder-text": "Optional: Working directory to use when debugging"}
    @cwdInput.type = "text"
    cwdGroup.appendChild @cwdInput

    div = document.createElement 'div'
    div.classList.add 'input-block-item'
    bgroup = document.createElement 'div'
    bgroup.classList.add 'btn-group'
    cwdButton = document.createElement 'button'
    cwdButton.classList.add 'btn', 'icon', 'icon-file-directory'
    cwdButton.textContent = "Choose Directory"
    cwdButton.addEventListener 'click', => @pickCwd()
    section.appendChild div
    div.appendChild bgroup
    bgroup.appendChild cwdButton

    # Start Button
    startGroup = document.createElement 'div'
    startGroup.classList.add 'block','input-block-item','pull-right','input-block-item--flex'
    @element.appendChild startGroup

    startButton = document.createElement 'button'
    startButton.classList.add 'btn-lg', 'btn-success', 'icon', 'icon-chevron-right'
    startButton.textContent = "Start"
    startButton.addEventListener 'click', => @startDebugging()
    startGroup.appendChild startButton

  pickFile: ->
    openOptions =
      properties: ['openFile', 'createDirectory']
      title: 'Select File'
    
    # Show the open dialog as child window on Windows and Linux, and as
    # independent dialog on macOS. This matches most native apps.
    parentWindow =
      if process.platform is 'darwin'
        null
      else
        require('electron').remote.getCurrentWindow()

    # File dialog defaults to project directory of currently active editor
    {dialog} = require('electron').remote
    file = dialog.showOpenDialog(parentWindow, openOptions)
    if file?
      @pathInput.model.buffer.setText(file[0])

  pickCwd: ->
    openOptions =
      properties: ['openDirectory', 'createDirectory']
      title: 'Select Folder'
    
    # Show the open dialog as child window on Windows and Linux, and as
    # independent dialog on macOS. This matches most native apps.
    parentWindow =
      if process.platform is 'darwin'
        null
      else
        require('electron').remote.getCurrentWindow()

    # File dialog defaults to project directory of currently active editor
    {dialog} = require('electron').remote
    folder = dialog.showOpenDialog(parentWindow, openOptions)
    if folder?
      @cwdInput.model.buffer.setText(folder[0])

  addDebuggerOption: (name) ->
    option = document.createElement('option')
    option.textContent = name
    @selectDebugger.appendChild option

  startDebugging: ->
    options = {debugger : null, path: null, args : null, cwd : null}
    if @pathInput.model.buffer.lines[0] != ""
      options.path = @pathInput.model.buffer.lines[0]
    else
      return
    if @selectDebugger.value != "auto"
      options.debugger = @selectDebugger.value
    if @argsInput.model.buffer.lines[0] != ""
      options.args = [ @argsInput.model.buffer.lines[0] ] # TODO: parse into args?
    if @cwdInput.model.buffer.lines[0] != ""
      options.cwd = @cwdInput.model.buffer.lines[0]
    @emitter.emit 'close'
    @bugger.debug(options)

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
