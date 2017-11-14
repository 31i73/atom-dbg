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
		@watcher.on 'error', (error) =>
			atom.notifications.addError 'Unable to monitor dbg config files',
				description: "A system error occurred trying to monitor dbg config files for updates (#{error?.code||'UNKNOWN'}).  \ndbg configurations will not automatically update if the files are modified."
				dismissable: true

	destructor: ->
		@watcher.close()

	readFile: (f) ->
		configs = {}
		try configs = switch path.extname f
			when '.json' then JSON.parse fs.readFileSync f
			when '.cson' then CSON.parse fs.readFileSync f
			else throw 'Unsupported file extension'

		catch error
			atom.notifications.addError "Error loading debug file `#{f}`",
				description: error.message
				dismissable: true
			console.error "Error loading debug file #{f}:\n", error
			delete @debugConfigs[f]

		basedir = path.dirname f
		configs[filename].basedir = basedir for filename of configs

		@debugConfigs[f] = configs

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
		# find the first config file within projectPaths[0] (only the first is used, as this is what debug paths are relative to by default)
		filename = null
		for configFilename of @debugConfigs
			if (path.dirname configFilename) == @projectPaths[0]
				filename = configFilename

		if !filename
			if !@projectPaths.length then return null
			filename = path.resolve @projectPaths[0], '.atom-dbg.cson'
		return filename

	getUniqueConfigName: (suggestion) ->
		names = (configOption.name for configOption in @getConfigOptions())
		name = suggestion
		nameCount = 1

		while (names.indexOf name) >= 0
			name = suggestion + ' ' + (++nameCount)

		return name

	saveOptions: (options) ->
		filename = @getDefaultConfigPath()
		if !filename then return

		name = @getUniqueConfigName if (options.path.charAt 0)!='/' then options.path else path.basename options.path

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
					stringifyIdentifier = (data) ->
						value = CSON.stringify data
						value = value.replace /^"([a-z0-9]+)"$/, '$1'
						return value

					data = data.replace /\s*$/, ''

					if data.length > 0
						data += '\n\n'

					data += (stringifyIdentifier name) + ':'
					for name of options
						if !options[name] || options[name] instanceof Array && options[name].length < 1
							continue

						data += '\n\t' + (stringifyIdentifier name) + ': ' + (CSON.stringify options[name])

					data += '\n'

			fs.writeFile filename, data, 'utf8'
