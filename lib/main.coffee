{CompositeDisposable} = require('atom')
{BasicTabButton} = require('atom-bottom-dock')
LinterManager = require('./views/linter-manager')

module.exports =
  activate: ->
    @subscriptions = new CompositeDisposable()
    @panes = []

    packageLinterFound = atom.packages.getAvailablePackageNames()
      .indexOf('linter') != -1

    packageBottomDockFound = atom.packages.getAvailablePackageNames()
      .indexOf('bottom-dock') != -1

    if not packageLinterFound
      @displayMissingPackageNotification('linter', 'https://atom.io/packages/linter')
    if not packageBottomDockFound
      @displayMissingPackageNotification('bottom-dock', 'https://atom.io/packages/bottom-dock')

    @subscriptions.add(atom.commands.add('atom-workspace', 'linter-manager:add': => @add()))
    @subscriptions.add(atom.packages.onDidActivatePackage((deactivatedPackage) =>
      @onPackageDeactivated(deactivatedPackage)
    ))

  displayMissingPackageNotification: (packagename, link) ->
    atom.notifications.addError("Could not find #{packageName}", {
      detail: "Todo-Manager: The #{packageName} package is a dependency. \n
      Learn more about #{packageName} here: #{link}",
      dismissable: true
    })

  onPackageDeactivated: (deactivatedPackage) ->
    if atom.packages.isPackageDisabled('linter')
      for pane in @panes
        @bottomDock.deletePane(pane.getId())
      @panes = []
    if atom.packages.isPackageDisabled('bottom-dock')
      @panes = []

  onPaneDeleted: (id) ->
    @panes = @panes.filter((p) -> return p.getId() != id)

  add: ->
    console.log('called')
    if @bottomDock and @linter and not atom.packages.isPackageDisabled('linter')
      newPane = new LinterManager(@linter)
      @panes.push(newPane)

      config =
        name: 'Linter'
        id: newPane.getId()
        active: newPane.isActive()

      newTabButton = new BasicTabButton(config)

      @bottomDock.addPane(newPane, newTabButton)

  deactivate: ->
    @subscriptions.dispose()
    for pane in @panes
      @bottomDock.deletePane(pane.getId())

  consumeBottomDock: (@bottomDock) ->
    @subscriptions.add(@bottomDock.onDidDeletePane((id) =>
      @onPaneDeleted(id)
    ))
    if @linter and not @panes.length
      @add()

  consumeLinter: (@linter) ->
    if @bottomDock and not @panes.length
      @add()
