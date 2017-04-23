
Blessed = require 'blessed'
Discord = require 'discord.js'

Debug = require './debug.js'
Storage = require( './storage.js' ).Storage

GuildList = require( './panels/guild-list.js' ).GuildList
ChannelList = require( './panels/channel-list.js' ).ChannelList
UserPanel = require( './panels/user.js' ).UserPanel
InputPanel = require( './panels/input.js' ).InputPanel
MessagePanel = require( './panels/message.js' ).MessagePanel
Notifications = require( './panels/notifications.js' ).Notifications



class MainScreen

	constructor: ( app ) ->

		@app = app
		@screen = app.screen
		@hooks = app.hooks
		@client = app.client

		Debug.init @screen

		@storage = new Storage app
		@storage.fill( )
		@storage.setupEvents( )


		@guild_list = new GuildList app, this
		@channel_list = new ChannelList app, this
		@user_panel = new UserPanel app, this
		@input_panel = new InputPanel app, this
		@message_panel = new MessagePanel app, this
		@notifications = new Notifications app, this


		@guild_list.setupUI( )
		@channel_list.setupUI( )
		@user_panel.setupUI( )
		@input_panel.setupUI( )
		@message_panel.setupUI( )
		@notifications.setupUI( )

		@guild_list.setupEvents( )
		@channel_list.setupEvents( )
		@user_panel.setupEvents( )
		@input_panel.setupEvents( )
		@message_panel.setupEvents( )
		@notifications.setupEvents( )


		@screen.append @guild_list.box
		@screen.append @channel_list.box
		@screen.append @user_panel.box
		@screen.append @message_panel.box
		@screen.append @input_panel.box
		@screen.append @notifications.box

		@screen.append @input_panel.suggestions_panel.box
		@screen.append @message_panel.popup.box

		@screen.render( )

		self = this
		@client.setTimeout( ->
			self.guild_list.repopulate self.storage.guilds
			self.channel_list.repopulate self.storage.getCurrentChannels( )
			self.user_panel.update( )

			self.screen.render( )
		, 100 )


exports.MainScreen = MainScreen
