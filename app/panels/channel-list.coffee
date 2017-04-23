
Blessed = require "blessed"

BaseList = require( "./base-list.js" ).BaseList
GuildList = require( "./guild-list.js" ).GuildList


class ChannelListItem

	constructor: ( app, storage, channel ) ->

		@app = app
		@storage = storage

		@channel = channel

		@text = ""

		@updateText( )


	updateText: ->

		options = @storage.getChannelData @channel
		states = @storage.getChannelStates @channel

		name = @channel.name

		if not @channel.guild?
			name = "@" + @storage.dmchannels_user[ @channel.id ].username

		if options.muted
			@text = "  {black-fg}#{name}{/}"
			return

		if states.unreaded
			@text = "* {bold}#{name}{/}"
		else
			@text = "  #{name}"




class ChannelList extends BaseList

	@WIDTH: 30


	constructor: ( app, mainscreen ) ->

		super app, mainscreen

		@client = app.client

		@position.top = 6
		@position.left = GuildList.WIDTH
		@position.width = ChannelList.WIDTH


	setupEvents: ->

		super( )

		self = this

		@storage.on "current-channel-changed", ( s, c ) ->
			for i in [0 ... self.list.length]
				if self.list[ i ].channel.id == c.id
					self.box.selected = i
					return


		@storage.on "channels-changed", ( s ) ->
			self.repopulate s.getCurrentChannels( )
			self.box.select 0
			self.app.screen.render( )

		@storage.on "channel-states-changed", ( s, c ) ->
			#if c.guild? and s.current_guild.id == c.guild.id
				self.update( )
				self.app.screen.render( )

		@box.on "select", ->

			item = self.list[ self.box.selected ]
			self.storage.selectChannel item.channel

			self.app.screen.render( )


	createItem: ( channel ) ->

		return new ChannelListItem @app, @storage, channel


	muteSelected: ( item ) ->

		chan = item.channel
		coptions = @storage.getChannelData chan
		coptions.muted = not coptions.muted
		@storage.setChannelData chan, coptions


exports.ChannelList = ChannelList
