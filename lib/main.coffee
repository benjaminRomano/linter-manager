{$} = require 'space-pen'
window.jQuery = $
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
      detail: "Linter-Manager: The #{packageName} package is a dependency. \n
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

  add: (isInitial) ->
    if atom.packages.isPackageDisabled 'linter'
      atom.notifications.addError "Cannot add linter pane",
        detail: "The linter package needs to enabled before a linter pane can be added"
      return
  
    if @bottomDock and @linter
      newPane = new LinterManager @linter
      
      @panes.push newPane

      @bottomDock.addPane newPane, 'Linter', isInitial
      
      @bottomDock.onDidToggle () =>
        newPane.resize() if newPane.active && @bottomDock.isActive()

  deactivate: ->
    @subscriptions.dispose()
    @bottomDock.deletePane pane.getId() for pane in @panes
    @linter = null
    @bottomDock = null

  consumeBottomDock: (@bottomDock) ->
    @subscriptions.add @bottomDock.onDidDeletePane (id) =>
      @onPaneDeleted(id)

    @subscriptions.add @bottomDock.onDidFinishResizing =>
      pane.resize() for pane in @panes

    if @linter and @panes.length is 0
      @add true

  consumeLinter: (@linter) ->
    if @bottomDock and @panes.length is 0
      @add true
