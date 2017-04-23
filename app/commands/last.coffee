
Command = require( "../command.js" ).Command


class LastCommand extends Command

	constructor: ( app, mainscreen ) ->

		super app, mainscreen, "last"
		@storage = mainscreen.storage

	haveSuggestions: ( argidx ) ->
		return argidx == 0

	suggestions: ( arg, argidx ) ->
		if argidx == 0
			return ["in-servers", "in-friends"].filter (a) -> a.startsWith arg
		return []

	argumentName: ( argidx ) ->
		if argidx == 0
			return "Where"

		return "Max 1 argument"

	execute: ( args ) ->

		notif = @mainscreen.notifications

		if args.length > 0

			if args[ 0 ] == "in-servers"

				if notif.last_guild_msgs.length == 0
					throw new Error "No new messages in any servers."

				m = notif.last_guild_msgs[ notif.last_guild_msgs.length - 1]

				c = m.channel
				g = m.guild

				@storage.selectGuild g, false
				@storage.selectChannel c

			if args[ 0 ] == "in-friends"

				if notif.last_friend_msgs.length == 0
					throw new Error "No new messages from any friends."

				m = notif.last_friend_msgs[ notif.last_friend_msgs.length - 1 ]

				c = m.channel

				@storage.selectGuild null, false
				@storage.selectChannel c

		else

			if notif.last_msgs.length == 0
				throw new Error "No new messages."

			m = notif.last_msgs[ notif.last_msgs.length - 1 ]


			c = m.channel
			g = m.guild

			@storage.selectGuild g, false
			@storage.selectChannel c



	getHelpText: ->
		return [
			"{magenta-fg}/last [where]{/}"
			""
			"Go to the last message."
			""
			"    {blue-fg}{bold}/last{/} : Go to the last message received."
			"    {blue-fg}{bold}/last in-servers : Go to the last message received in a server."
			"    {blue-fg}{bold}/last in-friends{/} : Go to the last direct message sent by a friend."
		]


exports.Command = LastCommand
