{View} = require('space-pen')

class Message extends View
  @content: (message) ->
    @div class: 'linter-message', =>
      if message.type
        messageTypeClass = 'linter-message-item badge badge-flexible linter-highlight '
        messageTypeClass += message.class if message.class
        @span outlet: 'messageType', class: messageTypeClass, message.type
      @span outlet: 'messageText', class: 'message-text', message.text if message.text
      @a click: 'onClick', outlet: 'messageLocation', class: 'linter-message-item'

  initialize: (@message, @options) ->
    messageLocation = ""
    messageLocation = "at line #{@message.range.start.row + 1} col #{@message.range.start.column + 1} " if @message.range

    if @options?.addPath
      displayFile = @message.filePath
      for path in atom.project.getPaths()
        continue if @message.filePath.indexOf(path) isnt 0 or displayFile isnt @message.filePath # Avoid double replacing
        displayFile = @message.filePath.substr( path.length + 1 ) # Remove the trailing slash as well
      messageLocation += "in #{displayFile}"

    if messageLocation
      @messageLocation.text(messageLocation)

  onClick: =>
    if @message.filePath
      @goToMatch(@message.filePath, @message.range)

  goToMatch: (filePath, range) ->
    atom.workspace.open(filePath).then ->
      return unless range
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(range.start)

module.exports = Message
