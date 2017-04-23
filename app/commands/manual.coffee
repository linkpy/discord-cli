
Command = require( "../command.js" ).Command

PAGES = {}

class ManualCommand extends Command

	constructor: ( app, mainscreen ) ->

		super app, mainscreen, "man"

		@_suggestions = []
		for page of PAGES
			@_suggestions.push page

	haveSuggestions: ( argidx ) ->
		return argidx == 0

	suggestions: ( arg, argidx ) ->
		if argidx == 0
			return @_suggestions.filter ( a ) ->
				return a.startsWith arg

		return []

	argumentName: ( argidx ) ->
		if argidx == 0
			return "Page Name"

		return "Max 1 argument"

	execute: ( args ) ->

		input_panel = @mainscreen.input_panel

		if args.length > 0

			page = PAGES[ args[ 0 ] ]
			if not page?
				throw new Error( "Page '#{args[0]}' doesn't exists.")

			input_panel.showCommandPanel page

		else
			throw new Error( "Command 'man' needs one argument." )


	getHelpText: ->
		return [
			"{magenta-fg}/man page-name{/}"
			""
			"Access to one of the page of the manual."
			""
			"{grey-fg}Note{/} : You can see the page list with {cyan-fg}'/man list'{/}"
		]


PAGES[ "list" ] = [
	"{#007F00-fg}{bold}List of manual pages :{/}"
	"  - {bold}input{/} - Page about the input box and the results panel."
	"  - {bold}lists{/} - Page about the server and the channel lists."
]

PAGES[ "input" ] = [
	"{#007F00-fg}{bold}Input Box & Results Panel :{/}"
	""
	"{bold}Note{/} : All the following shortcuts work when the input box has the"
	"    focus (when the cursor blink in it)."
	""
	"{bold}Input State{/} : The input state is the text above the input box."
	"    In its default state, it is 'Input'."
	""
	"{bold}When the input state is 'Input'{/} :"
	"    {red-fg}^X{/} : Toggle multiline edit."
	"    {red-fg}ENTER{/} : Send the message."
	"    Starting the line with a '{red-fg}/{/}' switch to command edit."
	""
	"{bold}When the input state is 'Input - Multiline ON'{/} :"
	"    {red-fg}^X{/} : Send the message and switch back to normal edit."
	"    {red-fg}ENTER{/} : New line."
	"    Deleting all the text will switch back to normal edit."
	""
	"{bold}When the input state is 'Input - Command'{/} :"
	"    {red-fg}ENTER{/} : Execute the command and switch back to normal edit."
	"    {red-fg}UP | DOWN{/} : Select suggestion."
	"    {red-fg}TAB{/} : Complete current element with the selected suggestion."
	"    Deleting the initial '{red-fg}/{/}' character will switch back to "
	"    normal edit."
	""
	"{bold}All the time{/} :"
	"    {red-fg}ESCAPE{/} : Unfocus the input text box."
	"    {red-fg}^R{/} : Show / Hide the result panel (the white area where you"
	"    are reading right now)."
]

PAGES[ "lists" ] = [
	""
]

exports.Command = ManualCommand
