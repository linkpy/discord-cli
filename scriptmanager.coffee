
fs = require "fs"


# The script manager handles the loading of user's scripts.
#
# A script must have the following structure :
#
#	initialize = ( hooks ) ->
# 		...
#
# 	exports.initialize = initilize
#
# The initialize function in the module exports will be call after the
# script is loaded.
#


# This function loads all the script in the given folder.
#
LoadScripts = ( path, hooks ) ->

	# We get all the files.
	files = fs.readdirSync path

	# We iterate over all files
	files.every ( file, index ) ->

		# We get the file's extension
		try
			extension = file.split( "." ).pop( )

		catch err

			console.error "Error while loading user script '#{file}'' : #{err}"
			console.error "Stack trace :"
			console.error err.stack
			process.exit 1

		# If the file is a javascript file
		if extension == "js"

			# We loads the scripts
			script = require path + "/" + file

			# If the script is loaded
			if script
				# We initialize it.
				try
					script.initialize hooks

				catch err
					console.error "Error while initializing user script '#{file}' : #{err}"
					console.error "Stack trace :"
					console.error err.stack
					process.exit 1

		return true


# Module's exports.
exports.LoadScripts = LoadScripts
