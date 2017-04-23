
Blessed = require "blessed"
Emoji = require "node-emoji"

Debug = require "../debug.js"

GuildList = require( "./guild-list.js" ).GuildList
ChannelList = require( "./channel-list.js" ).ChannelList
Suggestions = require( "./suggestions.js" ).Suggestions


class CommandSuggestions extends Suggestions

	constructor: ( app, mainscreen ) ->

		super app, mainscreen, 22, 10

	updatePosition: ( left ) ->

		@box.position.bottom = 2
		@box.position.left = left

		maxleft = @box.position.left + @box.width
		if maxleft > @app.screen.width
			@box.position.left -= maxleft - @app.screen.width



class InputPanel

	@LEFT: GuildList.WIDTH + ChannelList.WIDTH

	constructor: ( app, mainscreen ) ->

		@app = app
		@mainscreen = mainscreen
		@storage = mainscreen.storage

		@raw_input = ""

		@box = null
		@command_panel = null
		@suggestions_panel = new CommandSuggestions app, mainscreen,
		@input = null

		@multiline = false
		@command = false


	setupUI: ->

		@box = Blessed.box

			left: InputPanel.LEFT
			bottom: 0
			width: "100%-#{InputPanel.LEFT}"
			height: 4

			padding: 1

			content: "Input"
			tags: true
			align: "center"

			style:
				fg: "white"
				bg: "grey"

		@command_panel = Blessed.box

			parent: @box

			scrollable: true

			left: 0
			top: 1
			width: "100%-2"
			height: 3

			padding: 1

			tags: true

			style:
				fg: "black"
				bg: "white"

		@input = Blessed.textarea

			parent: @box

			clickable: true
			keyable: true
			scrollable: false
			inputOnFocus: true

			left: 0
			bottom: 0
			width: "100%-2"
			height: 1

			style:
				fg: "white"
				bg: "black"


		@suggestions_panel.setupUI( )

		@command_panel.hide( )
		@suggestions_panel.hide( )


	setupEvents: ->

		self = this
		@input.key "enter", ( ch, key ) ->

			if self.command
				self.executeCommand( )

				self.input.setValue ""
				self.box.setContent "Input"
				self.command = false

			else

				if not self.multiline
					self.box.setContent "Input"
					self.sendMessage( )
					self.multiline = false

				else
					self.updateHeight( )

			self.suggestions_panel.hide( )

			self.app.screen.render( )

		@input.key ["backspace", "delete"], ( ch, key ) ->
			if self.multiline

				if self.input.value.trim( ) == ""
					self.box.setContent "Input"
					self.multiline = false

				self.updateHeight( )

			if self.command

				if self.input.value.trim( ) == ""
					self.command = false
					self.suggestions_panel.hide( )

				else
					self.updateCommand( )

			else
				self.updateInput( )

			self.app.screen.render( )

		@input.key "C-x", ( ch, key ) ->

			if self.command
				return

			if not self.multiline
				self.multiline = true
				self.box.setContent "Input - Multiline ON"

			else
				self.box.setContent "Input"
				self.sendMessage( )
				self.multiline = false

			self.app.screen.render( )

		@input.on "keypress", ( ch, key ) ->

			if self.input.value[ 0 ] == "/"
				self.box.setContent "Input - Command"
				self.command = true
			else
				if self.command
					self.box.setContent "Input"
				self.command = false

			if key.name == "up"

				if self.suggestions_panel.visible( )
					self.suggestions_panel.up( )

				else if not self.command_panel.hidden
					self.command_panel.scroll -6

				else
					self.mainscreen.message_panel.up( )

			else if key.name == "down"

				if self.suggestions_panel.visible( )
					self.suggestions_panel.down( )

				else if self.command_panel.visible
					self.command_panel.scroll 6

				else
					self.mainscreen.message_panel.down( )

			else if key.name == "tab"

				if not self.suggestions_panel.hidden

					s = self.suggestions_panel.getSelected( )

					if self.command
						self.autocomplete s
					else
						self.autocompleteInput s

					self.suggestions_panel.hide( )

			else if self.command
				self.updateCommand ch, true

			else
				self.updateInput ch, true

			self.app.screen.render( )

		@input.key "tab", ( ch, key ) ->
			v = self.input.value
			self.input.setValue v.slice 0, v.length-1

		@input.key "C-r", ( ch, key ) ->
			self.command_panel.toggle( )
			self.updateHeight( )
			self.app.screen.render( )

		@input.on "cancel", ->

			if self.input.value.trim( ) == ""
				self.multiline = false
				self.command = false
				self.box.setContent "Input"
				self.updateHeight( )

			self.suggestions_panel.hide( )

			self.app.screen.render( )


		@command_panel.on "wheeldown", ->
			self.command_panel.scroll 6
			self.app.screen.render( )

		@command_panel.on "wheelup", ->
			self.command_panel.scroll -6
			self.app.screen.render( )


		@suggestions_panel.setupEvents( )



	updateHeight: ->

		if @multiline

			lines = @input.value.split( "\n" ).length

			if lines > 0

				@box.position.height = 3 + lines
				@input.position.height = lines

		else
			@box.position.height = 4
			@input.position.height = 1

		if @command_panel.visible
			@box.position.height += @command_panel.height

		@input.setValue @input.value


	updateSuggestions: ( txt, list, addone ) ->

		left = @box.position.left + 1 + @input.value.length

		if addone? and addone
			left += 1

		@suggestions_panel.show( )
		@suggestions_panel.update txt, list, left


	splitCommand: ( line, handleEndSpace ) ->

		input = line.slice 1
		lastIsSpace = input[ input.length-1 ] == " "

		temp = input.split ' '

		parts = []
		for i in [0 ... temp.length]
			part = temp[i].trim( )

			if part.length != 0
				parts.push part

		if parts.length == 0
			parts.push input.trim( )

		if handleEndSpace? and handleEndSpace and lastIsSpace
			parts.push ""

		return parts

	splitInput: ( input ) ->

		temp = input.split ' '

		parts = []
		for i in [0 ... temp.length]
			part = temp[i].trim( )

			if part.length != 0
				parts.push part

		if parts.length == 0
			parts.push input.trim( )

		return parts


	updateCommand: ( addch, addone ) ->

		input = @input.value

		if addch?
			input += addch

		args = @splitCommand input, true

		input = args[ 0 ]
		args.shift( )

		if args.length == 0
			list = @app.getCommandSuggestions input
			@updateSuggestions "Commands", list, addone

			return

		cmd = @app.commands[ input ]
		if not cmd?
			@updateSuggestions "Unknown command !", [], addone
			return

		if not cmd.haveSuggestions args.length - 1
			@suggestions_panel.hide( )
			return

		list = cmd.suggestions args[ args.length-1 ], args.length-1, args
		name = cmd.argumentName args.length-1
		@updateSuggestions name, list, addone


	updateInput: ( addch, addone ) ->

		input = @input.value

		if addch?
			input += addch

		parts = @splitInput input
		last = parts[ parts.length - 1 ]

		if last.startsWith "@<"
			if last[ last.length-1 ] != ">"
				@showMentionSuggestions last, addone
				return

		if last.startsWith "#"
			@showChannelSuggestions last, addone
			return

		if last.startsWith ":"
			if last.length >= 3 and not last.endsWith ":"
				@showEmojiSuggestions last, addone
				return

		@suggestions_panel.hide( )



	showMentionSuggestions: ( input, addone ) ->

		name = input.slice 2
		chan = @storage.current_channel

		if not name?
			@updateSuggestions "Mention", ["Invalid mention"], addone
			return

		if not chan.guild?
			@updateSuggestions "Mention", ["Not in a server"], addone
			return

		names = []
		for u in @storage.getLastActiveUsers chan
			uname = u.user.username

			if name.length == 0 or uname.startsWith name
				names.push "@<#{uname}>"

			if names.length > 15
				break

		if names.length == 0
			names = ["Invalid username"]

		@updateSuggestions "Mention", names, addone


	showChannelSuggestions: ( input, addone ) ->

		name = input.slice 1
		guild = @storage.current_guild

		if not guild?
			@updateSuggestions "Channel", ["Not in a server"], addone
			return

		if not guild.available
			@updateSuggestions "Channel", ["Server unavailable"], addone
			return

		names = []
		for c in guild.channels.array( )
			if @app.filterChannel c
				if name.length == 0 or c.name.startsWith name
					names.push "##{c.name}"

		if names.length == 0
			names = ["Invalid channel"]

		if names.length == 1 and names[0] == name
			@suggestions_panel.hide( )
			return

		@updateSuggestions "Channel", names, addone

	showEmojiSuggestions: ( input, addone ) ->

		name = input.slice 1

		names = []
		for e in Emoji.search name
			names.push ":#{e.key}:"

		if names.length == 0
			names = ["No match"]

		@updateSuggestions "Emoji", names, addone



	autocomplete: ( selected ) ->

		parts = @splitCommand @input.value, true
		parts[ parts.length-1 ] = selected

		@input.setValue "/" + parts.join ' '

	autocompleteInput: ( selected ) ->

		parts = @input.value.split " "

		if parts.length > 0
			parts[ parts.length - 1 ] = selected

		@input.setValue parts.join ' '


	executeCommand: ->

		args = @splitCommand @input.value

		cmd = @app.commands[ args[ 0 ] ]
		if not cmd?
			return

		args.shift( )

		try
			cmd.execute args

		catch err
			lines = ["{red-fg}{bold}Error executing command :"]
			lines = lines.concat err.stack.split '\n'
			lines[lines.length-1] += "{/}"
			@showCommandPanel lines


	sendMessage: ->

		content = @input.value
		chan = @storage.current_channel

		if content.trim( ).length != 0
			content = @parseContent content

			if chan?
				chan.sendMessage( content ).catch (err) ->
					throw err

		@input.setValue ""
		@input.position.height = 1
		@updateHeight( )
		@app.screen.render( )

	parseContent: ( txt ) ->

		self = this

		txt = txt.replace /#(\w+)/g, (match, p1) ->

			if not self.storage.current_guild?
				return match

			guild = self.storage.current_guild
			chan = null

			if not guild.available
				return match

			for c in guild.channels.array( )
				if c.name == p1
					chan = c
					break

			if not chan
				return match

			return "<##{chan.id}>"

		txt = txt.replace /@<([\w\s]+)>/g, (match, p1) ->

			if not self.storage.current_guild?
				return match

			guild = self.storage.current_guild

			if not guild.available
				return match

			member = null
			for m in guild.members.array( )
				if m.user.username == p1
					member = m
					break

			if not member?
				return match

			return "<@#{member.id}>"

		return txt




	showCommandPanel: ( lines ) ->

		@command_panel.show( )
		@command_panel.setContent ''

		if lines.length > @app.screen.height / 2 - 4
			@command_panel.position.height = Math.floor @app.screen.height / 2 - 2
		else
			@command_panel.position.height = lines.length + 2

		@updateHeight( )

		for line in lines
			@command_panel.pushLine line

	hideCommandPanel: ->

		@command_panel.hide( )
		@updateHeight( )
		@app.screen.render( )


exports.InputPanel = InputPanel
