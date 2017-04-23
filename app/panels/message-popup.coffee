
Blessed = require "blessed"

Debug = require "../debug.js"


class MessagePopup

	constructor: ( app, mainscreen ) ->

		@app = app
		@mainscreen = mainscreen
		@storage = mainscreen.storage

		@message = null
		@option_list = []

		@box = null
		@info = null
		@options = null


	setupUI: ->

		@box = Blessed.box

			top: "center"
			left: "center"
			width: 70
			height: 18

			clickable: true

			padding: 1
			border: 'line'

			style:
				fg: "white"
				bg: "black"

				border:
					fg: "white"
					bg: "black"


		@info = Blessed.text

			parent: @box

			top: 0
			left: 0

			tags: true

			style:
				fg: "white"
				bg: "black"


		@options = Blessed.list

			parent: @box

			bottom: 0
			left: 0
			width: "100%-3"
			height: 8

			mouse: true
			keys: true
			tags: true

			style:
				fg: "cyan"
				bg: "black"

				item:
					fg: "cyan"
					bg: "black"

				selected:
					fg: "black"
					bg: "cyan"

		@box.hide( )


	setupEvents: ->

		self = this
		@options.on "select", ->

			item = self.option_list[ self.options.selected ]

			if item == "edit"
				return

			if item == "pin"
				self.message.pin( ).catch (err) ->

				self.box.hide( )
				self.app.screen.render( )

			if item == "unpin"
				self.message.unpin( ).catch (err) ->

				self.box.hide( )
				self.app.screen.render( )

			if item == "delete"
				self.message.delete( ).catch (err) ->

				self.box.hide( )
				self.app.screen.render( )

			if item == "show mentions"
				return

			if item == "show reactions"
				return

			if item == "show attachments"
				return

			if item == "close"
				self.box.hide( )
				self.app.screen.render( )



	updateContent: (m) ->

		@message = m

		localdate = m.createdAt.toLocaleDateString( )
		localtime = m.createdAt.toLocaleTimeString( )

		umentions = m.mentions.users.array( ).length
		ureactions = m.reactions.array( ).length

		lines = []

		lines[0]  = "Sent by {bold}{cyan-fg}#{m.author.username}{/}{|}"
		lines[0] += "{grey-fg}#{localdate} - #{localtime}{/}"

		lines[1]  = "  Mentions {green-fg}#{umentions}{/} person(s)."
		lines[2]  = "  Has {green-fg}#{ureactions}{/} reaction(s)."

		if m.pinned
			lines[3] = "  This message is pinned to the current channel."

		@info.setContent ""

		for l in lines
			@info.pushLine l


		chan = m.channel

		items = []
		if chan.guild?

			u = chan.guild.member m.author
			cu = chan.guild.member @app.client.user

			authorIsClient = u.id == @app.client.user.id
			canManage = cu.hasPermission "MANAGE_MESSAGES"

			if m.type == "DEFAULT"

				if authorIsClient and not canManage
					items.push "edit"
					items.push "delete"

				if not authorIsClient and canManage
					if not m.pinned
						items.push "pin"
					else
						items.push "unpin"
					items.push "delete"

				if authorIsClient and canManage
					items.push "edit"
					if not m.pinned
						items.push "pin"
					else
						items.push "unpin"
					items.push "delete"

			if m.type == "PINS_ADD"
				if canManage
					items.push "delete"

			items.push "show mentions"
			items.push "show reactions"

		else

			authorIsClient = m.author.id == @app.client.user.id

			if authorIsClient
				items.push "edit"
				items.push "pin"
				items.push "delete"

			else
				items.push "pin"

			items.push "show reactions"

		if m.attachments.array( ).length != 0
			items.push "show attachments"

		items.push "close"

		@option_list = items
		@options.setItems items


	hide: -> @box.hide( )
	show: ->
		@box.show( )
		@options.focus( )


exports.MessagePopup = MessagePopup
