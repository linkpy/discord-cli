

class Command

	constructor: ( app, mainscreen, name ) ->

		@app = app
		@mainscreen = mainscreen
		@storage = mainscreen.storage

		@name = name


	haveSuggestions: ( argidx ) ->
		return false

	suggestions: ( arg, argidx, args ) ->
		return []

	argumentName: ( argidx ) ->
		return "Argument #{argidx}"


	execute: ( args ) ->
		throw new Error "Abstract function not implemented"


	getHelpText: ->
		throw new Error "Abstract function not implemented"


exports.Command = Command
