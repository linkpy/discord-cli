
Command = require( "../command.js" ).Command


class SendResultsCommand extends Command

	constructor: ( app, mainscreen ) ->

		super app, mainscreen, "send-results"

	haveSuggestions: ( argidx ) ->
		if argidx >= 0 and argidx <= 1
			return true


	suggestions: ( arg, argidx ) ->
		if argidx == 0
			return ["code", "raw"].filter (a) -> a.startsWith arg
		if argidx == 1
			return [
				"txt", "c", "c++", "lua", "java", "js",
				"coffee", "rust", "python", "bash", "batch",
				"sh"
			].filter (a) -> a.startsWith arg

		return []

	argumentName: ( argidx ) ->
		if argidx == 0
			return "Sending mode"
		if argidx == 1
			return "Code language"

		return "Max 2 argument"

	execute: ( args ) ->

		input_panel = @mainscreen.input_panel
		command_panel = input_panel.command_panel
		storage = @mainscreen.storage

		if args.length == 0
			args[0] = "code"
			args[1] = "txt"

		if args[0] == "code" and not args[1]?
			args[1] = "txt"

		content = ""

		if args[0] == "code"

			content = "```#{args[0]}\n"
			content += command_panel.getText( ) + "\n"
			content += "```"

		else if args[0] == "raw"
			content = command_panel.getText( )

		else
			throw new Error "Unknown mode '#{args[0]}'."

		chan = storage.current_channel
		chan.sendMessage( content ).catch (err) ->
			throw err



	getHelpText: ->
		return [
			"{magenta-fg}/send-results [mode] [code-lang]{/}"
			""
			"Send the content of the results to the current channel."
			""
			"    {blue-fg}{bold}/send-results raw{/} : Send without preformating."
			"    {blue-fg}{bold}/send-results code <language>{/} : Send with preformating."
		]


exports.Command = SendResultsCommand
