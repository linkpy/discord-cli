
Command = require( "../command.js" ).Command


class CloseResultsCommand extends Command

	constructor: ( app, mainscreen ) ->

		super app, mainscreen, "close-results"

	execute: ( args ) ->

		input_panel = @mainscreen.input_panel
		input_panel.hideCommandPanel( )


	getHelpText: ->
		return [
			"{magenta-fg}/close-result{/}"
			""
			"Close the result pannel."
			""
			"{grey-fg}Note{/} : You can show/hide the result pannel using ^R"
			"  with the focus on the text input box."
		]


exports.Command = CloseResultsCommand
