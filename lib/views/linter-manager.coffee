{DockPaneView, Toolbar, TableView, FilterSelector} = require 'atom-bottom-dock'
{CompositeDisposable, Emitter} = require 'atom'
{$} = require 'space-pen'

FilterConstants = require '../filter-constants'

class LinterManager extends DockPaneView
  @content: ->
    @div class: 'linter-manager', style: 'display:flex;', =>
      @subview 'toolbar', new Toolbar()

  initialize: (@linter) ->
    super()

    @subscriptions = new CompositeDisposable()

    @fileFilterSelector = new FilterSelector()
    @toolbar.addLeftTile item: @fileFilterSelector, priority: 0

    @count =
      file: 0
      project: 0
      line: 0

    @fileFilters =
      activeFilter: @linter.state.scope
      label: 'Messages For:'
      filters: [
        {
          value: FilterConstants.SCOPE.PROJECT
        }
        {
          value: FilterConstants.SCOPE.FILE
        }
      ]

    @messages = []

    columns = [
      {id: "linter", name: "Linter", field: "linter", sortable: true }
      {id: "type", name: "Type", field: "type", sortable: true }
      {id: "description", name: "Description", field: "description", sortable: true }
      {id: "path", name: "Path", field: "path", sortable: true }
      {id: "line", name: "Line", field: "line", sortable: true }
    ]

    @table = new TableView [], columns
    @append @table

    @table.onDidClickGridItem (row) =>
      @goToMatch row.message.filePath, row.message.range if row.message.filePath

    @subscriptions.add @fileFilterSelector.onDidChangeFilter @onFileFilterChanged
    @subscriptions.add @linter.onDidUpdateMessages @render
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem =>
      @render messages: @linter.messages.publicMessages

    @table.onDidFinishAttaching =>
      @render messages: @linter.messages.publicMessages

  setActive: (active) ->
    super(active)
    @table?.resize(true) if active

  resize: ->
    @table.resize(true)

  render: ({messages}) =>
    @messages = @classifyMessages messages
    @renderFileFilters()
    @renderMessages()

  onFileFilterChanged: (activeFilter) =>
    @linter.state.scope = activeFilter
    @renderFileFilters()
    @renderMessages()

  renderFileFilters: ->
    @fileFilters.activeFilter = @linter.state.scope
    @fileFilters.filters[0].label = "#{FilterConstants.SCOPE.PROJECT} #{@count.project}"
    @fileFilters.filters[1].label = "#{FilterConstants.SCOPE.FILE} #{@count.file}"
    @fileFilterSelector.updateFilters @fileFilters

  renderMessages: ->
    messages = []
    if @linter.state.scope is FilterConstants.SCOPE.PROJECT
      messages = @messages
    else if @linter.state.scope is FilterConstants.SCOPE.FILE
      messages = (message for message in @messages when message.currentFile)
    else if @linter.state.scope is FilterConstants.SCOPE.LINE
      messages = (message for message in @messages when message.currentLine)

    @table.deleteAllRows()


    data = (@createRow message  for message in messages)
    @table.addRows data

  createRow: (message) ->
    console.log message
    lineNumber = message.range?.start.row + 1 ? ""

    displayFile = message.filePath
    for path in atom.project.getPaths()
      # Avoid double replacing
      continue if message.filePath.indexOf(path) isnt 0 or displayFile isnt message.filePath

      # Remove the trailing slash as well
      displayFile = message.filePath.substr(path.length + 1)

    row =
      linter: message.linter
      type: message.type
      description: message.text
      path: displayFile
      line: lineNumber
      message: message

  goToMatch: (filePath, range) ->
    atom.workspace.open(filePath).then ->
      return unless range
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(range.start)

  classifyMessages: (messages) ->
    filePath = atom.workspace.getActiveTextEditor()?.getPath()
    @count.file = 0
    @count.project = 0
    for key, message of messages
      if message.currentFile = (filePath and message.filePath is filePath)
        @count.file++
      @count.project++
    return @classifyMessagesByLine messages

  classifyMessagesByLine: (messages) ->
    row = atom.workspace.getActiveTextEditor()?.getCursorBufferPosition().row
    @count.line = 0
    for key, message of messages
      if message.currentLine = (message.currentFile and message.range and message.range.intersectsRow row)
        @count.line++
    return messages

  destroy: ->
    @subscriptions.dispose if @subscriptions
    @remove()

module.exports = LinterManager
