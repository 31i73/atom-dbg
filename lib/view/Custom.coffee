module.exports =
class CustomDebugView
  constructor: (serializedState) ->
    # @subscriptions = new CompositeDisposable()
    
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('debug-custom')
    
    # debugger - Optional. The name of the dbg provider to use. (This can be omitted to auto-detect)
    # path - Optional. The path to the file to debug
    # args - Optional. An array of arguments to pass to the file being debugged
    # cwd - Optional. The working directory to use when debugging
    # ... - Optional. Custom debugger arguments
  
    # file to Debug
    fileGroup = document.createElement 'div'
    fileGroup.classList.add 'block'
    @element.appendChild fileGroup
    
    pathLabel = document.createElement 'label'
    pathLabel.textContent = "File to Debug"
    pathLabel.classList.add 'inline-block'
    fileGroup.appendChild pathLabel
    
    @pathInput = document.createElement 'input'
    @pathInput.classList.add 'inline-block', 'input-text'
    @pathInput.type = "text"
    # @subscriptions.add atom.tooltips.add @pathInput, title: 'File to Debug'
    fileGroup.appendChild @pathInput
    
    @pathButton = document.createElement 'button'
    @pathButton.classList.add 'inline-block', 'btn', 'icon', 'icon-file-directory'
    # @pathButton.addEventListener 'click', -> bugger.continue()
    # @subscriptions.add atom.tooltips.add @pathButton, title: 'Choose File to Debug'
    fileGroup.appendChild @pathButton

    # args
    argsGroup = document.createElement 'div'
    argsGroup.classList.add 'block'
    @element.appendChild argsGroup
    
    argsLabel = document.createElement 'label'
    argsLabel.textContent = "Arguments"
    argsLabel.classList.add 'inline-block'
    argsGroup.appendChild argsLabel
    
    @argsInput = document.createElement 'input'
    @argsInput.classList.add 'inline-block', 'input-text'
    # @subscriptions.add atom.tooltips.add @argsInput, title: 'Debugger arguements'
    argsGroup.appendChild @argsInput
    
    # working directory for debugger
    cwdGroup = document.createElement 'div'
    cwdGroup.classList.add 'block'
    @element.appendChild cwdGroup
    
    cwdLabel = document.createElement 'label'
    cwdLabel.classList.add 'inline-block'
    cwdLabel.textContent = "Working Directory"
    cwdGroup.appendChild cwdLabel
    
    # @cwdInput = document.createElement 'input'
    # @cwdInput.classList.add 'inline-block', 'input-text'
    # # @subscriptions.add atom.tooltips.add @cwdInput, title: 'Working directory path'
    # cwdGroup.appendChild @cwdInput
    
    @cwdInput = document.createElement 'atom-text-editor'
    @cwdInput.classList.add 'inline-block', 'editor', 'mini'
    # @subscriptions.add atom.tooltips.add @cwdInput, title: 'Working directory path'
    cwdGroup.appendChild @cwdInput
    
    @cwdButton = document.createElement 'button'
    @cwdButton.classList.add 'inline-block', 'btn', 'icon', 'icon-file-directory'
    # @cwdButton.addEventListener 'click', -> bugger.continue()
    # @subscriptions.add atom.tooltips.add @cwdButton, title: 'Choose working directory'
    cwdGroup.appendChild @cwdButton
    
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

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    # @subscriptions.dispose()
    @element.remove()

  getElement: ->
    @element
