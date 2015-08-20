{CompositeDisposable} = require 'atom'
LinterManager = require './views/linter-manager'

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable()
    @panes = []

    packageLinterFound = atom.packages.getAvailablePackageNames()
      .indexOf('linter') isnt -1

    packageBottomDockFound = atom.packages.getAvailablePackageNames()
      .indexOf('bottom-dock') isnt -1

    unless packageLinterFound
      @displayMissingPackageNotification 'linter', 'https://atom.io/packages/linter'

    unless packageBottomDockFound
      @displayMissingPackageNotification 'bottom-dock', 'https://atom.io/packages/bottom-dock'

    @subscriptions.add atom.commands.add 'atom-workspace', 'linter-manager:add': => @add()

    @subscriptions.add atom.packages.onDidDeactivatePackage (deactivatedPackage) =>
      @onPackageDeactivated(deactivatedPackage)


  displayMissingPackageNotification: (packageName, link) ->
    atom.notifications.addError "Could not find #{packageName}",
      detail: "Todo-Manager: The #{packageName} package is a dependency. \n
        Learn more about #{packageName} here: #{link}"
      dismissable: true


  onPackageDeactivated: (deactivatedPackage) ->
    if deactivatedPackage.name is 'linter'
      @bottomDock.deletePane pane.getId() for pane in @panes
      @linter = null

    if deactivatedPackage.name is 'bottom-dock'
      @panes = []
      @bottomDock = null

  onPaneDeleted: (id) ->
    @panes = (pane for pane in @panes when pane.getId() isnt id)

  add: ->
    if @bottomDock and @linter and not atom.packages.isPackageDisabled 'linter'
      newPane = new LinterManager @linter
      @panes.push newPane

      @bottomDock.addPane newPane, 'Linter'

  deactivate: ->
    @subscriptions.dispose()
    @bottomDock.deletePane pane.getId() for pane in @panes
    @linter = null
    @bottomDock = null

  consumeBottomDock: (@bottomDock) ->
    @subscriptions.add @bottomDock.onDidDeletePane (id) =>
      @onPaneDeleted(id)

    if @linter and @panes.length is 0
      @add()

  consumeLinter: (@linter) ->
    if @bottomDock and @panes.length is 0
      @add()
