
Blessed = require "blessed"

Debug = require '../debug.js'

GuildList = require( "./guild-list.js" ).GuildList
ChannelList = require( "./channel-list.js" ).ChannelList

MessageEntry = require( "./message-entry.js" ).MessageEntry
MessagePopup = require( "./message-popup.js" ).MessagePopup



class MessagePanel

	@LEFT: GuildList.WIDTH + ChannelList.WIDTH

	constructor: ( app, mainscreen ) ->

		@app = app
		@mainscreen = mainscreen
		@storage = mainscreen.storage

		@entries = []

		@box = null
		@popup = new MessagePopup app, mainscreen

		@selected = -1
		@offset = 0


	setupUI: ->

		@box = Blessed.box

			left: MessagePanel.LEFT
			top: 6
			width: "100%-#{MessagePanel.LEFT}"
			height: "100%-10"

			style:
				bg: "black"

		@popup.setupUI( )


	setupEvents: ->

		self = this

		@storage.on "current-channel-changed", ( s, c ) ->
			self.selected = -1
			self.repopulate s.current_messages
			self.app.screen.render( )

		@storage.on "current-messages-changed", (s) ->
			self.repopulate s.current_messages
			self.app.screen.render( )

		@popup.setupEvents( )


	populate: ( entries ) ->

		entries.sort (a, b) ->
			if a.createdTimestamp < b.createdTimestamp
				return -1
			if a.createdTimestamp > b.createdTimestamp
				return 1

			return 0

		self = this

		y = 0
		for entry in entries

			e = new MessageEntry @app, @mainscreen, this, entry

			e.index = @entries.length
			@entries.push e

			e.setupUI y
			e.setupEvents( )
			y += e.getHeight( )

			e.on "selected", (e) ->	self.select e

		if @selected > @entries.length-1
			@selected = -1

		if @selected >= 0
			@entries[ @selected ].select( )

		if y > @box.height

			@offset = -(@box.height - y)

			for entry in @entries
				entry.applyOffset @offset

				if entry.getTop( ) + entry.getHeight( ) < 0
					entry.hide( )


	repopulate: ( entries ) ->

		for entry in @entries
			entry.destroyUI( )

		@entries = []
		@populate entries



	select: (entry) ->

		if entry.index == @selected
			@popup.updateContent entry.message
			@popup.show( )

		else
			if @selected > 0
				@entries[@selected].unselect( )

			@selected = entry.index
			entry.select( )

		@app.screen.render( )

	selectIdx: (i) ->

		if @selected > 0
			@entries[@selected].unselect( )

		if i < 0
			i = 0
		if i >= @entries.length
			i = @entries.length-1

		@selected = i
		@entries[i].select( )

		@app.screen.render( )

	up: ->

		if @selected > 0
			@selectIdx @selected - 1

		else
			@selectIdx @entries.length-1

	down: ->

		if @selected > 0
			@selectIdx @selected + 1


exports.MessagePanel = MessagePanel
