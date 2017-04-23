
Command = require( "../command.js" ).Command

Debug = require "../debug.js"


class GotoPreviousCommand extends Command

	constructor: ( app, mainscreen ) ->

		super app, mainscreen, "goto-previous"

		@storage = mainscreen.storage

		@stack = []
		@ignore_change = false

		self = this
		@storage.on "current-channel-changed", (s, c, last) ->

			if not self.ignore_change and last?
				self.stack.push last

			self.ignore_change = false


	haveSuggestions: ( argidx ) ->
		return false

	suggestions: ( arg, argidx ) ->
		return []

	argumentName: ( argidx ) ->
		return "Max 0 argument"

	execute: ( args ) ->

		if @stack.length == 0
			throw new Error "No previously visited channel."

		c = @stack.pop( )
		@ignore_change = true

		if c.guild?
			@storage.selectGuild c.guild, false

		@storage.selectChannel c




	getHelpText: ->
		return [
			"{magenta-fg}/goto-previous{/}"
			""
			"Go to the previously visited channel. Can be done multiple time."
			""
			"    {blue-fg}{bold}/goto-previous{/} : Go to the previously visited channel."
		]


exports.Command = GotoPreviousCommand
