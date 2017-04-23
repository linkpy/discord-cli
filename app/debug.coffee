

Blessed = require "blessed"

screen = null
mbox = null

exports.init = ( scrn ) ->
	screen = scrn


exports.showMessage = (msg) ->

	if not mbox?
		mbox = Blessed.message
			left: "center"
			top: "center"
			width: "50%"
			height: "50%"
			bg: "green"
			fg: "black"
		screen.append mbox

	mbox.log String msg
	screen.render( )

exports.showError = (msg) ->

	if not mbox?
		mbox = Blessed.message
			left: "center"
			top: "center"
			width: "50%"
			height: "50%"
			bg: "green"
			fg: "black"
		screen.append mbox

	mbox.error String msg
	screen.render( )
