fs = require 'graceful-fs'
CSON = require 'cson'
_path = require 'path'
{CompositeDisposable} = require 'atom'
remote = require 'remote'
dialog = remote.require 'dialog'

convertEOL = (text) ->
  text.replace(/\r\n|\n|\r/g, '\n')

module.exports =
class AtomHelper
  constructor: (@virtualFileSystem) ->
    atom.packages.onDidActivateInitialPackages(@handleEvents)

  handleEvents: =>
    @disposables = new CompositeDisposable

    @disposables.add atom.commands.add body,
      'learn-ide:import': @onImport

    @disposables.add atom.workspace.observeTextEditors (editor) =>
      @disposables.add editor.onDidSave (e) =>
        @onEditorSave(e)

    @disposables.add atom.packages.onDidActivatePackage (pkg) =>
      return unless pkg.name is 'find-and-replace'

      projectFindView = pkg.mainModule.projectFindView
      resultModel = projectFindView.model

      @disposables.add resultModel.onDidReplacePath ({filePath}) =>
        @saveAfterProjectReplace(filePath)

    @disposables.add @package().onDidDeactivate =>
      @disposables.dispose()
      @virtualFileSystem.cache()

  package: ->
    atom.packages.getActivePackage('learn-ide-tree')

  treeView: ->
    @package()?.mainModule.treeView

  projectFindAndReplace: ->
    findAndReplace = atom.packages.getActivePackage('find-and-replace')
    projectFindView = findAndReplace.mainModule.projectFindView
    console.log projectFindView.model
    projectFindView.model

  findBuffer: (path) ->
    atom.project.findBufferForPath(path)

  findOrCreateBuffer: (path) ->
    atom.project.bufferForPath(path)

  # unimplemented: ({type}) =>
  #   command = type.replace(/^learn-ide:/, '').replace(/-/g, ' ')
  #   @warn 'Learn IDE: coming soon!', {detail: "Sorry, '#{command}' isn't available yet."}

  onLearnSave: ({target}) =>
    textEditor = atom.workspace.getTextEditors().find (editor) ->
      editor.element is target

    if not textEditor.getPath()?
      # TODO: this happens if an untitled editor is saved
      return console.log 'Cannot save file without path'

    text = convertEOL(textEditor.getText())
    content = new Buffer(text).toString('base64')
    @virtualFileSystem.save(textEditor.getPath(), content)

  onEditorSave: ({path}) =>
    node = @virtualFileSystem.getNode(path)

    node.determineSync().then (shouldSync) =>
      if shouldSync
        @findOrCreateBuffer(path).then (textBuffer) =>
          text = convertEOL(textBuffer.getText())
          content = new Buffer(text).toString('base64')
          @virtualFileSystem.save(path, content)

  saveAfterProjectReplace: (path) =>
    fs.readFile path, 'utf8', (err, data) =>
      if err
        return console.error "Project Replace Error", err

      text = convertEOL(data)
      content = new Buffer(text).toString('base64')
      @virtualFileSystem.save(path, content)

  # addMenu: ->
  #   path = _path.join(__dirname, '..', 'menus', 'menu.cson')

  #   fs.readFile path, (err, data) ->
  #     if err?
  #       return console.error "Unable to add menu:", err

  #     atom.menu.add CSON.parse(data)

  # addKeymaps: ->
  #   path = _path.join(__dirname, '..', 'keymaps', 'keymaps.cson')

  #   fs.readFile path, (err, data) ->
  #     if err?
  #       return console.error "Unable to add keymaps:", err

  #     atom.keymaps.add path, CSON.parse(data)

  # addContextMenus: ->
  #   path = _path.join(__dirname, '..', 'menus', 'context-menus.cson')

  #   fs.readFile path, (err, data) ->
  #     if err?
  #       return console.error "Unable to add context-menus:", err

  #     atom.contextMenu.add CSON.parse(data)

  onImport: =>
    dialog.showOpenDialog
      title: 'Import Files',
      properties: ['openFile', 'multiSelections']
    , (paths) => @importLocalPaths(paths)


  importLocalPaths: (localPaths) ->
    localPaths = [localPaths] if typeof localPaths is 'string'
    targetPath = @treeView().selectedPath
    targetNode = @virtualFileSystem.getNode(targetPath)

    localPaths.forEach (path) =>
      fs.readFile path, 'base64', (err, data) =>
        if err?
          return console.error 'Unable to import file:', path, err

        base = _path.basename(path)
        newPath = _path.posix.join(targetNode.path, base)

        if @virtualFileSystem.hasPath(newPath)
          @warn 'Learn IDE: cannot save file',
            detail: """There is already an existing remote file with path:
                    #{newPath}"""
          return

        @virtualFileSystem.save(newPath, data)

