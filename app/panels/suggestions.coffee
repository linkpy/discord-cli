
Blessed = require "blessed"


class Suggestions

	constructor: ( app, mainscreen, width, height ) ->

		@app = app
		@mainscreen = mainscreen

		@width = width
		@height = height

		@box = null
		@list = null
		@rawlist = []


	setupUI: ->

		@box = Blessed.box

			width: @width
			height: @height

			align: "center"

			padding:
				top: 1
				left: 1
				right: 1
				bottom: 1

			style:
				fg: "green"
				bg: "blue"

		@list = Blessed.list

			parent: @box

			mouse: true
			keys: false
			tags: true

			items: []

			left: 0
			top: 1
			width: "100%-2"
			height: "100%-2"

			align: "center"

			style:
				fg: "white"
				bg: "blue"

				selected:
					fg: "blue"
					bg: "white"

				item:
					fg: "white"
					bg: "blue"

		@box.hide( )

	setupEvents: ->


	update: ( txt, list, left ) ->

		@box.setContent txt
		@list.clearItems( )
		@list.setItems list
		@rawlist = list

		@updatePosition left
		@app.screen.render( )

	updatePosition: ( left ) ->
		throw new Error "Abstract function not implemented"


	show: -> @box.show( )
	hide: -> @box.hide( )
	up: -> @list.up 1
	down: -> @list.down 1


	getSelected: ->
		return @rawlist[ @list.selected ]

	visible: ->
		return not @box.hidden


exports.Suggestions = Suggestions
