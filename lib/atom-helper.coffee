fs = require 'graceful-fs'
CSON = require 'cson'
_path = require 'path'
{CompositeDisposable} = require 'atom'

convertEOL = (text) ->
  text.replace(/\r\n|\n|\r/g, '\n')

module.exports =
class AtomHelper
  constructor: (@virtualFileSystem) ->
    atom.packages.onDidActivateInitialPackages(@handleEvents)

  handleEvents: =>
    @disposables = new CompositeDisposable

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

  projectFindAndReplace: ->
    findAndReplace = atom.packages.getActivePackage('find-and-replace')
    projectFindView = findAndReplace.mainModule.projectFindView
    console.log projectFindView.model
    projectFindView.model

  saveAfterProjectReplace: (path) =>
    fs.readFile path, 'utf8', (err, data) =>
      if err
        return console.error "Project Replace Error", err

      text = convertEOL(data)
      content = new Buffer(text).toString('base64')
      @virtualFileSystem.save(path, content)

