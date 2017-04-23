
Blessed = require "blessed"


GuildList = require( "./guild-list.js" ).GuildList
ChannelList = require( "./channel-list.js" ).ChannelList

class UserPanel

	constructor: ( app, mainscreen ) ->

		@app = app
		@mainscreen = mainscreen
		@storage = mainscreen.storage
		@user = app.client.user

		@box = null
		@dmchannel = null


	setupUI: ->

		@box = Blessed.box

			top: 0
			left: 0
			width: GuildList.WIDTH + ChannelList.WIDTH
			height: 7

			padding: 1

			tags: true

			style:
				fg: "white"
				bg: "grey"

		@dmchannel = Blessed.button

			parent: @box

			clickable: true
			keyable: false

			top: 4
			left: 1
			width: "40%"
			height: 1

			content: "Friends"
			align: "center"

			style:
				fg: "black"
				bg: "white"

				hover:
					fg: "black"
					bg: "green"
				focus:
					fg: "green"
					bg: "black"



	setupEvents: ->

		self = this

		@storage.on "current-guild-changed", ( s ) ->
			self.update( )

		@storage.on "current-channel-changed", ( s ) ->
			self.update( )

		@dmchannel.on "click", -> self.dmchannel.press( )
		@dmchannel.on "press", ->

			self.storage.selectGuild null



	update: ->

		guild = @storage.current_guild
		channel = @storage.current_channel

		@box.setContent ''

		@box.setLine 0, "Logged in as {bold}{magenta-fg}#{@user.username}{/}"

		if guild?
			@box.setLine 1, " on {bold}{cyan-fg}#{guild.name}{/}"
			@box.setLine 2, " in \#{bold}#{channel.name}{/}"
		else
			friend = @storage.dmchannels_user[ channel.id ]
			if friend?
				@box.setLine 1, " speaking with {bold}{cyan-fg}#{friend.username}{/}"
			else
				@box.setLine 1, " speaking with {bold}{cyan-fg}????{/}"




exports.UserPanel = UserPanel
