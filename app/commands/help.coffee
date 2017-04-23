
Command = require( "../command.js" ).Command


class HelpCommand extends Command

	constructor: ( app, mainscreen ) ->

		super app, mainscreen, "help"

	haveSuggestions: ( argidx ) ->
		return argidx == 0

	suggestions: ( arg, argidx ) ->
		if argidx == 0
			return @app.getCommandSuggestions arg
		return []

	argumentName: ( argidx ) ->
		if argidx == 0
			return "Command Name"

		return "Max 1 argument"

	execute: ( args ) ->

		input_panel = @mainscreen.input_panel

		if args.length > 0

			cmd = @app.commands[ args[ 0 ] ]
			if not cmd?
				throw new Error( "Command '#{args[0]}' doesn't exists.")

			input_panel.showCommandPanel cmd.getHelpText( )

		else

			input_panel.showCommandPanel [
				"Use the manual {cyan-fg}'/man'{/} for the manual pages."
			]


	getHelpText: ->
		return [
			"{magenta-fg}/help [cmd]{/}"
			""
			"Get general help, or get command help text."
			""
			"    {blue-fg}{bold}/help{/} : Get general help."
			"    {blue-fg}{bold}/help <command>{/} : Get help for the given command."
		]


exports.Command = HelpCommand
