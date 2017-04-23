
EventEmitter = require "events"

Debug = require "./debug.js"


class Storage extends EventEmitter

	@INITIAL_MESSAGE_FETCH: 50
	@MAX_MESSAGES: Storage.INITIAL_MESSAGE_FETCH * 2

	constructor: ( app ) ->

		super( )

		@app = app
		@client = app.client

		@users = {}
		@guilds = []
		@channels = []
		@messages = {}

		@dmchannels = []
		@dmchannels_user = {}

		@users_data = {}
		@guilds_data = {}
		@channels_data = {}

		@users_states = {}
		@guilds_states = {}
		@channels_states = {}

		@current_guild = null
		@current_channels = null
		@current_messages = null


	fill: ->

		self = this

		@guilds = @client.guilds.array( )

		for guild in @guilds

			if not guild.available
				continue

			@channels = @channels.concat guild.channels.array( ).filter ( c ) ->
				return self.app.filterChannel c

			gdata = @app.getGuildOptions guild.id
			@guilds_data[ guild.id ] = gdata

		for chan in @channels

			if not @app.filterChannel chan
				continue

			@messages[ chan.id ] = []

			cdata = @app.getChannelOptions chan.id
			@channels_data[ chan.id ] = cdata

		for chan in @getDMChannels( )

			@dmchannels.push chan

			@messages[ chan.id ] = []

			cdata = @app.getChannelOptions chan.id
			@channels_data[ chan.id ] = cdata


		@current_guild = @guilds[ 0 ]
		currentchan = @getCurrentChannels( )[ 0 ]
		if currentchan?
			@selectChannel currentchan


	setupEvents: ->

		self = this

		@client.on "guildCreate", ( g ) -> self.storeGuild g
		@client.on "guildDelete", ( g ) -> self.removeGuild g
		@client.on "guildUpdate", ( oldg, newg ) ->	self.updateGuild oldg, newg


		@client.on "channelCreate", ( c ) ->

			if not self.app.filterChannel c
				return

			if not self.channels_data[ c.id ]?
				cdata = self.app.getChannelOptions c.id
				self.channels_data[ c.id ] = cdata

			if c.type == "text"
				self.channels.push c
			else
				self.dmchannels.push c

			self.messages[ c.id ] = []
			self.emit "channel-new", self, c

		@client.on "channelDelete", ( c ) ->

			for i in [0 ... self.channels.length]

				if self.channels[ i ].id == c.id

					self.emit "channel-remove", self, c

					self.channels.splice i, 1
					delete self.messages[ c.id ]
					break

		@client.on "channelUpdate", ( oldc, newc ) ->

			for i in [0 ... self.channels.length]

				if self.channels[ i ].id == oldc

					self.channels[ i ] = newc
					self.emit "channel-update", self, oldc, newc
					break

		@client.on "channelPinsUpdate", ( c ) ->

			mesgs = self.messages[ c.id ]

			c.fetchPinnedMessages( ).then( (ms) ->

				for i in [mesgs.length ... 0] by -1

					mesgs[i].pinned = false

					for m in ms.array( )
						if mesgs[i].id == m.id
							mesgs[i].pinned = true

				if c.id == self.current_channel.id
					self.emit "current-messages-changed", self

			).catch (err) ->



		@client.on "message", ( m ) ->

			c = m.channel
			mesgs = self.messages[ c.id ]

			if not mesgs?
				self.messages[ c.id ] = []
				mesgs = self.messages[ c.id ]

			mesgs.push m

			if mesgs.length > Storage.MAX_MESSAGES
				mesgs.splice 0, mesgs.length - Storage.MAX_MESSAGES


			us = self.getUserStates( m.author )
			us.lastMesgsTimestamps[ c.id ] = m.createdTimestamp
			self.setUserStates m.author, us


			self.setUnread m
			self.emit "message-new", self, m, c

			if c.id == self.current_channel.id
				self.emit "current-messages-changed", self


		@client.on "messageDelete", ( m ) ->

			c = m.channel
			if not self.messages[ c.id ]?
				return

			msgs = self.messages[ c.id ]

			for i in [msgs.length-1 ... 0] by -1

				if msgs[i].id == m.id

					self.emit "message-remove", self, m, c
					msgs.splice i, 1

					if c.id == self.current_channel.id
						self.emit "current-messages-changed", self

					break

		@client.on "messageUpdate", ( oldm, newm ) ->

			c = oldm.channel

			if not self.messages[ c.id ]?
				return

			msgs = self.messages[ c.id ]

			for i in [msgs.length-1 ... 0] by -1

				if msgs[i].id == oldm.id

					msgs[i] = newm
					self.emit "message-update", self, oldm, newm, c

					if c.id == self.current_channel.id
						self.emit "current-messages-changed", self




	storeGuild: ( g ) ->

		self = this

		@guilds.push g

		if not g.available
			return

		@channels.concat g.channels

		for chan in g.channels.array( )

			@messages[ chan.id ] = []

			if not @channels_data[ chan.id ]?
				cdata = @app.getChannelOptions chan.id
				@channels_data[ chan.id ] = cdata

			@emit "channel-new", self, chan

		@emit "guild-new", self, g

		@emit "guilds-changed", self
		@emit "channels-changed", self


	removeGuild: ( g ) ->

		for i in [0 ... @guilds.length]

			if @guilds[ i ].id == g.id
				@guilds.splice i, 1
				break

		tmp_removelist = []
		for i in [0 ... @channels.length]

			for c in g.channels.array( )

				if @channels[ i ].id == c.id

					@emit "channel-remove", self, c

					tmp_removelist.push i
					delete @messages[ c.id ]


		for i in [0 ... tmp_removelist.length]

			@channels.splice tmp_removelist[ i ] - i, 1

		@emit "guild-remove", self, g

		@emit "guilds-changed", self
		@emit "channels-changed", self



	updateGuild: ( oldg, newg ) ->

		for i in [0 ... @guilds.length]

			if @guilds[ i ].id == oldg

				@guilds[ i ] = newg
				@emit "guild-update", self, oldg, newg
				@emit "guilds-changed", self

				break


	selectGuild: ( guild, emit ) ->

		if @current_guild? and guild? and guild.id == @current_guild.id
			return

		@current_guild = guild
		@selectChannel @getCurrentChannels( )[ 0 ], emit
		@emit "current-guild-changed", this, guild
		@emit "channels-changed", this

	selectChannel: ( channel, emit ) ->

		if emit? and not emit
			return

		if @current_channel? and @current_channel.id == channel.id
			return

		if not @messages[ channel.id ]?
			@messages[ channel.id ] = []

		last = @current_channel

		if @messages[ channel.id ].length < Storage.INITIAL_MESSAGE_FETCH

			self = this
			channel.fetchMessages( {limit: Storage.INITIAL_MESSAGE_FETCH} ).then( (m) ->
				self.messages[ channel.id ] = m.array( )

				for m in self.messages[ channel.id ]
					us = self.getUserStates m.author
					us.lastMesgsTimestamps[ channel.id ] = m.createdTimestamp
					self.setUserStates m.author, us

				if self.current_channel.id == channel.id
					self.current_messages = self.messages[ channel.id ]
					self.emit "current-messages-changed", self

				self.emit "messages-changed", self

			).catch (err) ->
				throw err


		@current_channel = channel
		@current_messages = @messages[ channel.id ]
		@setRead channel

		@emit "current-channel-changed", this, channel, last
		@emit "current-messages-changed", this
		@emit "messages-changed", this


	setUnread: ( mesg ) ->

		chan = mesg.channel
		guild = mesg.guild

		if chan.id == @current_channel.id
			return

		cstates = @getChannelStates chan
		if cstates.unreaded then return
		cstates.unreaded = true
		@setChannelStates chan, cstates

		if guild?
			gstates = @getGuildStates guild
			gstates.unreaded += 1
			@setGuildStates guild, gstates

	setRead: ( chan ) ->

		cstates = @getChannelStates chan
		if not cstates.unreaded then return
		cstates.unreaded = false
		@setChannelStates chan

		guild = chan.guild

		if guild?
			gstates = @getGuildStates guild
			gstates.unreaded -= 1
			@setGuildStates guild, gstates


	getCurrentChannels: ->

		if not @current_guild?
			return @dmchannels

		if not @current_guild.available
			return []

		self = this
		return @current_guild.channels.array( ).filter ( chan ) ->
			return self.app.filterChannel chan

	getDMChannels: ->

		user = @client.user

		if not user?
			return []

		friends = user.friends.array( )
		list = []

		for friend in friends
			if friend.dmChannel?
				@dmchannels_user[ friend.dmChannel.id ] = friend
				list.push friend.dmChannel

		return list

	sortDMChannels: ( list ) ->

		self = this
		list.sort ( a, b ) ->

			mesgsA = self.messages[ a.id ]
			mesgsB = self.messages[ b.id ]

			if mesgsA? and not msgsB?
				return 1
			if not mesgsA? and msgsB?
				return -1
			if not mesgsA? and not mesgsB?
				return 0

			lastAT = mesgsA[ mesgsA.length-1 ].createdTimestamp
			lastBT = mesgsB[ mesgsB.length-1 ].createdTimestamp

			if lastAT > lastBT
				return 1
			if lastAT < lastBT
				return -1

			return 0


	getLastActiveUsers: ( channel ) ->

		if not channel.guild?
			return []

		self = this

		members = channel.members.array( )
		members.sort ( a, b ) ->
			as = self.getUserStates( a ).lastMesgsTimestamps[ channel.id ] or 0
			bs = self.getUserStates( b ).lastMesgsTimestamps[ channel.id ] or 0

			if as > bs
				return 1
			if as < bs
				return -1

			return 0

		return members





	getUserData: ( user ) ->

		if not @users_data[ user.id ]?
			@users_data[ user.id ] = {muted: false}

		return @users_data[ user.id ]

	getGuildData: ( guild ) ->

		if not @guilds_data[ guild.id ]?
			@guilds_data[ guild.id ] = @app.getGuildOptions guild.id

		if not @guilds_data[ guild.id ]?
			@guilds_data[ guild.id ] = {muted: false}

		return @guilds_data[ guild.id ]

	getChannelData: ( channel ) ->

		if not @channels_data[ channel.id ]?
			@channels_data[ channel.id ] = @app.getChannelOptions channel.id

		if not @channels_data[ channel.id ]?
			@channels_data[ channel.id ] = {muted: false}

		return @channels_data[ channel.id ]


	setUserData: ( user, data ) ->
		@users_data[ user.id ] = data

	setGuildData: ( guild, data ) ->
		@guilds_data[ guild.id ] = data

		@emit "guild-states-changed", this, guild

	setChannelData: ( channel, data ) ->
		@channels_data[ channel.id ] = data

		@emit "channel-states-changed", this, channel


	getUserStates: ( user ) ->

		if not @users_states[ user.id ]?
			@users_states[ user.id ] = {lastMesgsTimestamps: {}}

		return @users_states[ user.id ]

	getGuildStates: ( guild ) ->

		if not @guilds_states[ guild.id ]?
			@guilds_states[ guild.id ] = {unreaded: 0}

		return @guilds_states[ guild.id ]

	getChannelStates: ( channel ) ->

		if not @channels_states[ channel.id ]?
			@channels_states[ channel.id ] = {unreaded: false}

		return @channels_states[ channel.id ]


	setUserStates: ( user, states ) ->
		@users_states[ user.id ] = states

	setGuildStates: ( guild, states ) ->
		@guilds_states[ guild.id ] = states

		@emit "guild-states-changed", this, guild

	setChannelStates: ( channel, states ) ->
		@channels_states[ channel.id ] = states

		@emit "channel-states-changed", this, channel



exports.Storage = Storage
