fs = require 'fs'
path = require 'path'
CSON = require 'cson-parser'
chokidar = require 'chokidar'

module.exports =
class CustomDebugConfigs
	constructor: () ->
		@debugConfigs = {}
		@watcher = null

		@startWatching atom.project.getPaths()

		atom.project.onDidChangePaths (projectPaths) =>
			@debugConfigs = {}
			@watcher.close
			@startWatching projectPaths

	startWatching: (dirs) ->
		#TODO: this glob works, but for some reason it grabs more files than expected
		# globs = [path.resolve p, "**",".atom-debug.[jc]son" for p in dirs] # watch recursivly in directories
		globs = [path.resolve p,".atom-debug.[jc]son" for p in dirs] # only watch in directories
		@watcher = chokidar.watch globs
		@watcher.on 'add', (f) => @updateConfig f
		@watcher.on 'change', (f) => @updateConfig f
		@watcher.on 'unlink', (f) => delete @debugConfigs[f]

	destructor: () ->
		@watcher.close

	updateConfig: (f) ->
		switch path.extname f
			when '.json'
				@debugConfigs[f] = JSON.parse fs.readFileSync f
			when '.cson'
				@debugConfigs[f] = CSON.parse fs.readFileSync f

	getConfigs: ->
		configs = {}
		for f of @debugConfigs
			Object.assign(configs, @debugConfigs[f])
		return configs
