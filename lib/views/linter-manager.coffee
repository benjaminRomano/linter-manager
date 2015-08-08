{DockPaneView} = require('atom-bottom-dock')
{CompositeDisposable, Emitter} = require('atom')
{$} = require('space-pen')
_ = require('lodash')

FilterSelector = require('./filter-selector')
FilterConstants = require('../filter-constants')
Message = require('./message')

class LinterManager extends DockPaneView
  @content: ->
    @div class: 'linter-manager', =>
      @div outlet: 'filters', class: 'filters', =>
        @subview 'fileFilterSelector', new FilterSelector()
      @div outlet: 'messageContainer', class: 'message-container', ->

  initialize: (@linter) ->
    super()
    @subscriptions = new CompositeDisposable()

    @count =
      file: 0
      project: 0
      line: 0

    @fileFilters =
      activeFilter: @linter.state.scope
      label: 'Messages For:'
      filters: [
        {
          name: FilterConstants.scope.project
        }
        {
          name: FilterConstants.scope.file
        }
      ]

    @messages = []

    @subscriptions.add(@fileFilterSelector.onDidChangeFilter(@onFileFilterChanged))
    @subscriptions.add(@linter.onDidUpdateMessages(@render))
    @subscriptions.add(atom.workspace.onDidChangeActivePaneItem( =>
      @render({ messages: @linter.messages.publicMessages }))
    )

    @render({ messages: @linter.messages.publicMessages })

  render: ({messages}) =>
    @messages = @classifyMessages(messages)
    @renderFileFilters()
    @renderMessages()

  onFileFilterChanged: (activeFilter) =>
    @linter.state.scope = activeFilter
    @renderFileFilters()
    @renderMessages()

  renderFileFilters: ->
    @fileFilters.activeFilter = @linter.state.scope
    @fileFilters.filters[0].label = FilterConstants.scope.project + ' ' + @count.project
    @fileFilters.filters[1].label = FilterConstants.scope.file + ' ' + @count.file
    @fileFilterSelector.updateFilters(@fileFilters)

  renderMessages: ->
    messages = []
    if @linter.state.scope is FilterConstants.scope.project
      messages = @messages
    else if @linter.state.scope is FilterConstants.scope.file
      messages = @messages.filter((message) ->
        return message.currentFile
      )
    else if @linter.state.scope is FilterConstants.scope.line
      messages = @messages.filter((message) ->
        return message.currentLine
      )

    @messageContainer.empty()

    for message in messages
      @messageContainer.append(new Message(message, {
        addPath: @linter.state.scope is FilterConstants.scope.project
      }))

  classifyMessages: (messages) ->
    filePath = atom.workspace.getActiveTextEditor()?.getPath()
    @count.file = 0
    @count.project = 0
    for key, message of messages
      if message.currentFile = (filePath and message.filePath is filePath)
        @count.file++
      @count.project++
    return @classifyMessagesByLine(messages)

  classifyMessagesByLine: (messages) ->
    row = atom.workspace.getActiveTextEditor()?.getCursorBufferPosition().row
    @count.line = 0
    for key, message of messages
      if message.currentLine = (message.currentFile and message.range and message.range.intersectsRow(row))
        @count.Line++
    return messages

  refresh: ->

  destroy: ->
    @subscriptions.dispose if @subscriptions
    @remove()

module.exports = LinterManager
