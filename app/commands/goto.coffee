
Command = require( "../command.js" ).Command

Debug = require '../debug.js'

class GotoCommand extends Command

	constructor: ( app, mainscreen ) ->

		super app, mainscreen, "goto"
		@storage = mainscreen.storage
		@lastGuild = ""


	haveSuggestions: ( argidx ) ->
		return true


	suggestions: ( arg, argidx, args ) ->

		line = args.join( ' ' ).trim( )
		fc = line[0]

		if fc != "#" and fc != "@"
			return @suggestionsGuildChan args

		if fc == "#"
			return @suggestionsChan args

		if fc == "@"
			return @suggestionsFriends args

		return []


	argumentName: ( argidx ) ->
		return "Target"


	execute: ( args ) ->

		line = args.join( ' ' ).trim( )
		fc = line[0]

		if fc != "#" and fc != "@"
			@executeGuildChan args

		else if fc == "#"
			@executeChan args

		else if fc == "@"
			@executeFriends args

		else
			throw new Error "Invalid argument(s)"



	suggestionsGuildChan: ( args ) ->

		line = args.join ' '
		sepi = line.indexOf "#"

		guildname = ""
		channelname = ""

		if sepi == -1
			guildname = line.trim( )

			names = []
			for guild in @storage.guilds
				if guild.available
					if guild.name.startsWith line
						names.push guild.name

			return names

		guildname = line.slice( 0, sepi ).trim( )
		channelname = line.slice( sepi+1 ).trim( )

		guild = null
		for g in @storage.guilds
			if g.available and g.name == guildname
				guild = g
				break

		if not guild
			return [ "Unknown Guild" ]

		names = []
		for chan in guild.channels.array( )
			if @app.filterChannel chan
				if chan.name.startsWith channelname
					names.push "#" + chan.name

		return names

	suggestionsChan: ( args ) ->

		line = args[0].slice( 1 )
		guild = @storage.current_guild

		if guild == null
			return ["Not in a server"]

		names = []
		for chan in guild.channels.array( )
			if @app.filterChannel chan
				if chan.name.startsWith line
					names.push "#" + chan.name

		return names

	suggestionsFriends: ( args ) ->

		line = args.join( ' ' ).trim( ).slice 1
		friends = @storage.client.user.friends.array( )

		names = []
		for friend in friends
			if friend.username.startsWith line
				names.push "@" + friend.username

		return names



	executeGuildChan: ( args ) ->

		line = args.join ' '
		sepi = line.indexOf "#"


		if sepi == -1

			guild = null

			for g in @storage.guilds
				if g.available and g.name == line.trim( )
					guild = g
					break

			if not guild?
				throw new Error "Server '#{line.trim( )}' doesn't exists."

			@storage.selectGuild guild

		else

			gname = line.slice( 0, sepi ).trim( )
			cname = line.slice( sepi+1 ).trim( )

			guild = null
			chan = null

			for g in @storage.guilds
				if g.available and g.name == gname
					guild = g
					break

			if not guild?
				throw new Error "Server '#{gname}' doesn't exists."

			if not guild.available
				throw new Error "Can't go to channel '#{cname}' : server unavailable."


			for c in guild.channels.array( )
				if c.name == cname
					chan = c
					break

			if not chan
				throw new Error "Channel '#{cname}' doesn't exists in the given server."

			@storage.selectGuild guild, false
			@storage.selectChannel chan

	executeChan: ( args ) ->

		line = args[ 0 ].slice 1

		guild = @storage.current_guild
		chan = null

		if not guild?
			throw new Error "Not in a server."

		if not guild.available
			throw new Error "Can't go to channel '#{line}' : server unavailable."

		for c in guild.channels.array( )
			if c.name == line
				chan = c
				break

		if not chan?
			throw new Error "Channel '#{line}' doesn't exists in the given server."

		@storage.selectChannel chan

	executeFriends: ( args ) ->

		line = args.join( ' ' ).trim( ).slice 1
		friends = @storage.client.user.friends.array( )

		for friend in friends
			if not friend?
				throw new Error "wut"

			if friend.username == line
				chan = friend.dmChannel

				if not chan?
					throw new Error "Can't go to '@#{line}' : no direct-message channel."

				@storage.selectGuild null, false
				@storage.selectChannel chan
				return

		throw new error "Friend @'#{line}' doesn't exists."


	getHelpText: ->
		return [
			"{magenta-fg}/goto <server name> [#channel name]{/}"
			"{magenta-fg}/goto <#channel name>{/}"
			"{magenta-fg}/goto <@friend username>{/}"
			""
			"Go to the given server and channel (if given)."
			""
			"    {blue-fg}{bold}/goto <server name>{/} : Go to the general channel of the given server."
			"    {blue-fg}{bold}/goto <server name> #<channel name>{/} : Go to the given channel in the given server."
			"    {blue-fg}{bold}/goto #<channel name>{/} : Go to the given channel in the current server."
			"    {blue-fg}{bold}/goto @<friend name>{/} : Go to the friend direct-message channel."
		]


exports.Command = GotoCommand
