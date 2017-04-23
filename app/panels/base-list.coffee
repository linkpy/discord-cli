
Blessed = require "blessed"

Debug = require '../debug.js'


class BaseList

	constructor: ( app, mainscreen ) ->

		@app = app
		@mainscreen = mainscreen
		@storage = mainscreen.storage

		@list = []

		@box = null
		@mute = null

		@position = {
			left: 0
			top: 0
			width: 0
		}



	setupUI: ->

		@box = Blessed.list

			mouse: true
			keys: true
			tags: true

			items: []

			left: @position.left
			top: @position.top
			width: @position.width
			height: "100%-#{@position.top}"

			padding:
				top: 3
				left: 1
				right: 1

			style:

				bg: "grey"

				item:
					fg: "white"
					bg: "grey"

				selected:
					fg: "cyan"
					bg: "grey"

				focus:
					item:
						fg: "yellow"

		@mute = Blessed.button

			parent: @box

			clickable: true
			keyable: false

			top: -2
			left: 1
			width: "100%-4"
			height: 1

			content: "Toggle Muted"
			align: "center"

			style:
				fg: "black"
				bg: "white"

				hover:
					fg: "black"
					bg: "red"
				focus:
					fg: "red"
					bg: "black"

	setupEvents: ->

		self = this

		@mute.on "click", (m) -> self.mute.press( )
		@mute.on "press", ->

			item = self.list[ self.box.selected ]

			if item?
				self.muteSelected item


	destroyUI: ->

		@box.destroy( )
		@box = null



	populate: ( entries ) ->

		for entry in entries

			item = @createItem entry

			@list.push item
			@box.addItem item.text

	repopulate: ( entries ) ->

		@list = []

		oldSelected = @box.selected
		@box.clearItems( )

		@populate entries

		if oldSelected <= @list.length
			@box.select oldSelected


	update: ->

		i = 0
		for item in @list

			item.updateText( )
			@box.setItem i, item.text
			i += 1


	createItem: ( entry ) ->
		throw new Error "Abstract function not implemented."

	muteSelected: ( item ) ->
		throw new Error "Abstract function not implemented."


exports.BaseList = BaseList
