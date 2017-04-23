
Blessed = require "blessed"
EventEmitter = require "events"

MessageParser = require "../utils/message-parser.js"

Debug = require "../debug.js"


wrapsplit = ( str, width ) ->

	sum = ( arr ) ->
		out = 0

		if arr.length != 0
			for word in arr
				out += word.length

			return out + arr.length - 1

		return 0

	lines = [[]]
	split = str.split ' '

	for word in split

		if sum( lines[ lines.length-1 ] ) + word.length > width
			lines.push []

		lines[ lines.length-1 ].push word

	for i in [ 0 ... lines.length ]
		lines[i] = lines[i].join " "

	return lines

wrapsplitml = ( str, width ) ->

	parts = str.split "\n"

	if parts.length == 0
		return wrapsplit str, width

	out = []
	for part in parts
		out = out.concat wrapsplit part, width

	return out

wordwrap = ( str, width, brk ) ->

	brk = brk or '\n'
	return wrapsplit( str, width ).join brk



class MessageEntry extends EventEmitter

	constructor: ( app, mainscreen, pannel, m ) ->

		super( )

		@app = app
		@mainscreen = mainscreen
		@storage = mainscreen.storage
		@pannel = pannel

		@channel = m.channel
		@guild = @channel.guild

		@message = m
		@has_text = m.content.length != 0
		@has_attachements = m.attachments.array( ).length != 0

		@user = m.author
		@guild_member = null
		@guild_role = null

		@index = -1

		@box = null
		@author = null
		@content = null
		@attachments = null


		@updateRole( )



	setupUI: (top) ->

		@box = Blessed.box

			parent: @pannel.box

			clickable: true
			keyable: false

			top: top
			left: 0
			width: "100%"
			height: 1

			style:
				bg: "black"

		@author = Blessed.text

			parent: @box

			clickable: true
			tags: true

			top: 0
			left: 0

			style:
				fg: "white"
				bg: "black"

		@content = Blessed.text

			parent: @box

			clickable: true
			tags: true

			top: 0
			left: 20

			style:
				fg: "grey"
				bg: "black"

		@attachments = Blessed.text

			parent: @box

			clickable: true
			top: 0
			left: 20

			style:
				fg: "cyan"
				bg: "black"

		@fill( )


	destroyUI: ->

		@attachments.destroy( )
		@content.destroy( )
		@author.destroy( )
		@box.destroy( )


	setupEvents: ->

		self = this

		@box.on "click", ->
			self.emit "selected", self

		@author.on "click", ->
			self.emit "selected", self
			self.emit "author-clicked", self

		@content.on "click", ->
			self.emit "selected", self

		@attachments.on "click", (mouse) ->
			self.emit "selected", self

			list = self.message.attachments.array( )
			idx = mouse.y - self.attachments.atop
			attachment = list[ idx ]

			if attachment?
				self.emit "attachment-clicked", self,
			else
				throw new Error( )



	updateRole: ->

		if @guild? and @guild.available

			@guild_user = @message.member
			if not @guild_user?
				return

			@guild_role = @guild_user.highestRole



	fill: ->

		self = this


		author = @user.username.slice 0, 18
		attachments = []
		lines = []

		if @message.type == "DEFAULT" and @has_text
			mw = @box.width - 22
			lines = wrapsplitml MessageParser.Parse( @app, @message ), mw

		else if @message.type == "PINS_ADD"
			@has_text = true
			lines = [
				"{yellow-fg}has pinned a new message to this channel.{/}"
			]

		for a in @message.attachments.array( )

			size = Math.round( a.filesize / 1024 * 1000 ) / 1000
			attachments.push "[#{a.filename} - #{size}Ko]"

		lines = lines.filter (l) -> return l.length != 0


		if @has_text
			@box.position.height = lines.length
			@content.show( )
		else
			@content.hide( )

		if @has_attachements
			if not @has_text
				@box.position.height = attachments.length
			else
				@attachments.position.top = lines.length
				@box.position.height += attachments.length
			@attachments.show( )
		else
			@attachments.hide( )

		if @guild_role
			@author.setContent "{#{@guild_role.hexColor}-fg}#{author}{/}"
		else
			@author.setContent author

		for l in lines
			@content.pushLine l

		for a in attachments
			@attachments.pushLine a

		@box.position.height += 1


	applyOffset: ( offs ) ->
		@box.position.top -= offs



	hide: -> @box.hide( )


	select: ->
		@box.style.bg = "white"
		@author.style.bg = "white"
		@content.style.bg = "white"
		@attachments.style.bg = "white"

	unselect: ->
		@box.style.bg = "black"
		@author.style.bg = "black"
		@content.style.bg = "black"
		@attachments.style.bg = "black"


	getTop: ->
		return @box.position.top

	getHeight: ->
		return @box.position.height

exports.MessageEntry = MessageEntry
