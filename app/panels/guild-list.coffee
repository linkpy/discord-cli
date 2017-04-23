
Blessed = require "blessed"

Debug = require "../debug.js"

BaseList = require( "./base-list.js" ).BaseList


class GuildListItem

	constructor: ( app, storage, guild ) ->

		@app = app
		@storage = storage

		@guild = guild

		@text = ""

		@updateText( )


	updateText: ->

		if not @guild.available
			@text = "  {red-fg}Unavailable{/}"
			return

		options = @storage.getGuildData @guild
		states = @storage.getGuildStates @guild

		showntext = @guild.name

		if showntext.length > GuildList.MAX_STR_LENGTH
			showntext = @getAcronym( )

		if options.muted
			@text = "  {black-fg}#{showntext}{/}"
			return

		if states.unreaded > 0
			@text = "* {bold}#{showntext}{/}"
		else
			@text = "  #{showntext}"

	getAcronym: ->
		return @guild.name.match( /\b(\w)/g ).join( '' ).toUpperCase( )




class GuildList extends BaseList

	@WIDTH: 22
	@MAX_STR_LENGTH: @WIDTH - 4


	constructor: ( app, mainscreen ) ->

		super app, mainscreen

		@client = app.client

		@position.top = 6
		@position.width = GuildList.WIDTH


	setupEvents: ->

		super( )

		self = this

		@storage.on "current-guild-changed", ( s, g ) ->
			if not g?
				return

			for i in [0 ... self.list.length]
				if self.list[ i ].guild.id == g.id
					self.box.selected = i
					return

		@storage.on "guilds-changed", ( s ) ->
			self.repopulate s.guilds
			self.app.screen.render( )

		@storage.on "guild-states-changed", ( s, g ) ->
			self.update( )
			self.app.screen.render( )


		@box.on "select", ->

			item = self.list[ self.box.selected ]
			self.storage.selectGuild item.guild

			self.app.screen.render( )


	createItem: ( guild ) ->

		return new GuildListItem @app, @storage, guild


	muteSelected: ( item ) ->

		guild = item.guild
		goptions = @storage.getGuildData guild
		goptions.muted = not goptions.muted
		@storage.setGuildData guild, goptions


exports.GuildList = GuildList
