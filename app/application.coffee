
# Loading libs
Blessed = require "blessed"
Discord = require "discord.js"
FS = require "fs"
INI = require "ini"

Debug = require "./debug.js"

# Loading the login screen.
LoginScreen = require( "./login-screen.js" ).LoginScreen
MainScreen = require( "./main-screen.js" ).MainScreen

BUILTIN_COMMANDS = [
	"./commands/help.js"
	"./commands/close-results.js"
	"./commands/manual.js"
	"./commands/send-results.js"
	"./commands/goto.js"
	"./commands/last.js"
	"./commands/goto-previous.js"
]


class Application

	constructor: ( hooks ) ->

		@screen = null
		@client = null
		@token = null
		@config = null
		@hooks = hooks

		@mainscreen = null
		@commands = {}

		@userRoleCache = {}
		@userGuildCache = {}

		@messages = {}

		# We create the screen
		@screen = Blessed.screen
			smartCSR: true
			fullUnicode: true

		# We setup a exit shortcut
		self = this
		@screen.key "C-c", ( ch, key ) ->
			self.screen.destroy( )
			return process.exit 0

		# We load the configuration file.
		@config = INI.parse FS.readFileSync "./config.ini", "utf-8"

		# We emit the preinit hook
		hooks.emit "preinit", this

		# We start the login screen and wait
		new LoginScreen this, ->
			self.onClientReady( )


	getStoredToken: ->

		if @config.login? and @config.login.token?
			return @config.login.token

		return ""

	setStoredToken: ( token ) ->

		if not @config.login?
			@config.login = {}

		@config.login.token = token


	prepareLogin: ( client, token ) ->
		@client = client
		@token = token

	confirmLogin: ( client, token ) ->
		self = this

		@client = client
		@token = token

		@screen.unkey "C-c"
		@screen.key "C-c", ( ch, key ) ->
			self.screen.destroy( )
			client.destroy( )
			return process.exit 0

		@hooks.emit "logged", this, client


	onClientReady: ->

		if not @mainscreen?

			@mainscreen = new MainScreen this

			@registerBuiltinCommands( )
			@hooks.emit "client-ready", this, @client



	memberCanReadChannel: ( user, chan ) ->

		if not user.guild?
			user = chan.guild.member user

		if not user? or not user.guild?
			return false

		if user.guild != chan.guild
			return false

		p = chan.permissionsFor user
		return p.hasPermission "READ_MESSAGES"

	filterChannel: ( chan ) ->

		if chan.type == "dm" or chan.type == "text"
			if @memberCanReadChannel @client.user, chan
				return true

		return false


	registerCommand: ( cmd ) ->

		if @commands[ cmd.name ]?
			throw new Error "The command '#{cmd.name}' is already registered"

		@commands[ cmd.name ] = cmd

	registerBuiltinCommands: ->

		for path in BUILTIN_COMMANDS

			mod = require path
			@registerCommand new mod.Command this, @mainscreen


	getCommandSuggestions: ( input ) ->

		list = []

		for name of @commands
			if input.length != 0
				if name.startsWith input
					list.push name
			else
				list.push name

		list.sort( )

		return list


	getGuildOptions: ( id ) ->

		id = "guild-#{id}"
		if @config[ id ]?
			return @config[ id ]

		return {
			muted: false
		}

	setGuildOptions: ( id, options ) ->

		id = "guild-#{id}"
		@config[ id ] = options


	getChannelOptions: ( id ) ->

		id = "channel-#{id}"
		if @config[ id ]?
			return @config[ id ]

		return {
			muted: false
		}

	setChannelOptions: ( id, options ) ->

		id = "channel-#{id}"
		@config[ id ] = options


	getCachedUserGuild: ( guildid, userid ) ->

		if not @userGuildCache[ guildid ]?
			@userGuildCache[ guildid ] = {}
			return null

		return @userGuildCache[ guildid ][ userid ]

	setCachedUserGuild: ( guildid, userid, guilduser ) ->

		if not @userGuildCache[ guildid ]?
			@userGuildCache[ guildid ] = {}

		@userGuildCache[ guildid ][ userid ] = guilduser


	getCachedUserRole: ( guildid, userid ) ->

		if not @userRoleCache[ guildid ]?
			@userRoleCache[ guildid ] = {}
			return null

		return @userRoleCache[ guildid ][ userid ]

	setCachedUserRole: ( guildid, userid, role ) ->

		if not @userRoleCache[ guildid ]?
			@userRoleCache[ guildid ] = {}

		@userRoleCache[ guildid ][ userid ] = role



exports.Application = Application
