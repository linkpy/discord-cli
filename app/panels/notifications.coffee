
Blessed = require "blessed"

GuildList = require( "./guild-list.js" ).GuildList
ChannelList = require( "./channel-list.js" ).ChannelList


class Notifications

	@LEFT: GuildList.WIDTH + ChannelList.WIDTH
	@WIDTH: 80

	@MAX_MESSAGES: 50


	constructor: ( app, mainscreen ) ->

		@app = app
		@mainscreen = mainscreen
		@storage = mainscreen.storage

		@last_guild_msgs = []
		@last_friend_msgs = []
		@last_msgs = []

		@box = null


	setupUI: ->

		@box = Blessed.box

			left: Notifications.LEFT
			top: 0
			width: Notifications.WIDTH
			height: 5

			tags: true

			style:
				fg: "white"
				bg: "grey"

	setupEvents: ->

		self = this
		@storage.on "message-new", ( s, m, c ) ->

			if m.author.id == self.app.client.user.id
				return

			if c.id == self.storage.current_channel.id
				return

			if c.guild?
				if self.storage.getGuildData( c.guild ).muted
					return

			if self.storage.getChannelData( c ).muted
				return

			self.last_msgs.push m

			if c.guild?
				self.last_guild_msgs.push m
			else
				self.last_friend_msgs.push m

			self.update( )
			self.app.screen.render( )

		@storage.on "current-channel-changed", ->
			self.removeReaded( )
			self.update( )
			self.app.screen.render( )


	update: ->

		@box.setContent ""

		if @last_msgs.length == 0
			return

		lines = []

		lm = @last_msgs[ @last_msgs.length-1 ]
		lgm = null
		lfm = null

		if @last_guild_msgs.length > 0
			lgm = @last_guild_msgs[ @last_guild_msgs.length-1 ]

		if @last_friend_msgs.length > 0
			lfm = @last_friend_msgs[ @last_friend_msgs.length-1 ]


		lines[0]  = "Last message by {cyan-fg}@#{lm.author.username}{/}"

		if lm.channel.guild?

			g = lm.channel.guild
			c = lm.channel
			lines[0] += " on {red-fg}#{g.name}{/} in {yellow-fg}##{c.name}{/}"

		if lgm? and lgm.channel.guild.available

			g = lgm.channel.guild
			c = lgm.channel

			l  = "  in servers : {cyan-fg}@#{lgm.author.username}{/}"
			l += " on {red-fg}#{g.name}{/} in {yellow-fg}##{c.name}{/}"
			lines.push l

		if lfm?

			l  = "  in friends : {cyan-fg}@#{lfm.author.username}{/}"
			lines.push l

		for l in lines
			@box.pushLine l

	removeReaded: ->

		cc = @storage.current_channel

		@last_msgs = @last_msgs.filter (a) ->
			return a.channel.id != cc.id

		@last_guild_msgs = @last_guild_msgs.filter (a) ->
			return a.channel.id != cc.id

		@last_friend_msgs = @last_friend_msgs.filter (a) ->
			return a.channel.id != cc.id


exports.Notifications = Notifications
