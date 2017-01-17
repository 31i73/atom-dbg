fs = require 'fs'
path = require 'path'
CSON = require 'cson-parser'
chokidar = require 'chokidar'
{Workspace} = require 'atom'

module.exports =
class ConfigManager
	constructor: ->
		@debugConfigs = {}
		@watcher = null
		@projectPaths = []

		@startWatching atom.project.getPaths()

		atom.project.onDidChangePaths (projectPaths) =>
			@debugConfigs = {}
			@watcher.close
			@startWatching projectPaths

	startWatching: (dirs) ->
		@projectPaths = dirs
		#TODO: this glob works, but for some reason it grabs more files than expected
		# globs = [path.resolve p, "**",".atom-dbg.[jc]son" for p in dirs] # watch recursivly in directories
		globs = [path.resolve p,".atom-dbg.[jc]son" for p in dirs] # only watch in directories
		@watcher = chokidar.watch globs
		@watcher.on 'add', (f) => @readFile f
		@watcher.on 'change', (f) => @readFile f
		@watcher.on 'unlink', (f) => delete @debugConfigs[f]

	destructor: ->
		@watcher.close()

	readFile: (f) ->
		try @debugConfigs[f] = switch path.extname f
			when '.json' then JSON.parse fs.readFileSync f
			when '.cson' then CSON.parse fs.readFileSync f
			else throw 'Unsupported file extension'

		catch error
			console.error "Error loading #{f}:\n", error
			delete @debugConfigs[f]

	getConfigOptions: ->
		configs = []
		for f of @debugConfigs
			configFile = @debugConfigs[f]
			configs.push {name:name, config:configFile[name]} for name of configFile
		return configs

	openConfigFile: ->
		filename = @getDefaultConfigPath()
		if !filename then return

		atom.workspace.open filename

	getDefaultConfigPath: ->
		filename = (Object.keys @debugConfigs )[0]
		if !filename
			if !@projectPaths.length then return null
			filename = path.resolve @projectPaths[0], '.atom-dbg.cson'
		return filename

	getUniqueConfigName: (suggestion) ->
		names = configOption.name for configOption in @getConfigOptions()
		name = suggestion
		nameCount = 1

		while (names.indexOf name) >= 0
			name = suggestion + ' ' + (++nameCount)

		return name

	saveOptions: (options) ->
		filename = @getDefaultConfigPath()
		if !filename then return

		name = @getUniqueConfigName path.basename options.path

		if !@debugConfigs[filename]
			@debugConfigs[filename] = {}
		@debugConfigs[filename][name] = options

		fs.readFile filename, 'utf8', (err, data) =>
			if err
				if err.code == 'ENOENT'
					data = ''
				else
					throw err

			switch path.extname filename
				when '.json'
					data = data.replace /\s*}?\s*$/, '' # remove closing }
					data = data.replace /([^{])$/, '$1,' # continuing comma if any previous data

					data += '\n\t' + (JSON.stringify name) + ': {'
					first = true
					for name of options
						if !options[name] || options[name] instanceof Array && options[name].length < 1
							continue

						if !first then data += ','

						data += '\n\t\t' + (JSON.stringify name) + ': ' + (JSON.stringify options[name])
						first = false

					data += '\n\t}'
					data += '\n}'
					data += '\n'

				when '.cson'
					stringify = (data) ->
						value = CSON.stringify data
						value = value.replace /^"([a-z0-9]+)"$/, '$1'
						return value

					data = data.replace /([^\r\n])\s*$/, '$1'

					data += '\n'
					data += '\n' + (stringify name) + ':'
					for name of options
						if !options[name] || options[name] instanceof Array && options[name].length < 1
							continue

						data += '\n\t' + (stringify name) + ': ' + (stringify options[name])

					data += '\n'

			fs.writeFile filename, data, 'utf8'
