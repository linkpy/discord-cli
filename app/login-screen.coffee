
# Loading libs
Blessed = require "blessed"
Discord = require "discord.js"


# The login screen handles the login process of the client.
#
class LoginScreen

	# Constructor.
	#
	# `app` is the application instance.
	# `logincb` is the callback called when the client is ready.
	#
	constructor: ( app, logincb ) ->

		# We keep the app instance
		@app = app

		# We initialize the UI elements
		@form = null
		@label = null
		@in_token = null
		@checkb_savetok = null
		@error = null
		@but_submit = null
		@but_exit = null

		# We keep the login callback
		@logincallback = logincb

		# We setup the UI then the callbacks
		@setupUI( )
		@setupCallbacks( )

		# We runs the login-screen hook.
		app.hooks.emit "login-screen", app, this

		# Then we render the screen.
		@app.screen.render( )


	# This function setups all UI elements of the login screen.
	#
	setupUI: ->

		@form = Blessed.form

			keys: true
			focused: true

			top: 'center'
			left: 'center'
			width: '75%'
			height: 14

			content: 'Discord CLI Client - Login'
			align: 'center'

			border:
				type: 'line'

			style:
				fg: 'white'

				border:
					fg: 'blue'


		@label = Blessed.text

			parent: @form

			top: 2
			left: 2

			content: 'Token :'


		@in_token = Blessed.textbox

			parent: @form
			name: 'token'

			inputOnFocus: true

			top: 3
			left: 2
			width: "100%-6"
			height: 1

			style:
				fg: 'cyan'
				bg: 'grey'


		@checkb_savetok = Blessed.checkbox

			parent: @form
			name: "save_token"

			checked: false
			mouse: true

			top: 5
			left: 2
			width: "100%-6"
			height: 1

			content: "Save token to the configuration file for next logins (not safe !)"


		@error = Blessed.text

			parent: @form

			top: 8
			left: 2

			style:
				fg: 'red'


		@but_submit = Blessed.button

			parent: @form

			top: 10
			left: 2
			width: "45%"
			height: 1

			content: "Submit"
			align: 'center'

			style:
				fg: "green"
				bg: "grey"

				focus:
					fg: "grey"
					bg: "green"

				hover:
					bg: "white"


		@but_exit = Blessed.button

			parent: @form

			top: 10
			right: 2
			width: '45%'
			height: 1

			content: "Exit"
			align: 'center'

			style:
				fg: 'red'
				bg: 'grey'

				focus:
					fg: 'grey'
					bg: 'red'

				hover:
					bg: 'white'


		# We add the root element to the screen
		@app.screen.append @form
		# And we loads the stored token.
		@in_token.setValue @app.getStoredToken( )


	# This function setups all the UI callbacks.
	#
	setupCallbacks: ->
		self = this

		# We define this convinient callback for mouse usage
		@but_submit.on 'click', @but_submit.press
		@but_exit.on 'click', @but_exit.press

		@but_submit.on 'press', ->
			self.form.submit( )

		@but_exit.on 'press', ->
			self.destroyUI( )
			process.exit 0

		@form.on 'submit', ( data ) ->
			self.tryLogin data.token, data.save_token


	# This function destroy every UI elements.
	#
	destroyUI: ->
		@form.hide( )
		@app.screen.render( )

		@but_exit.destroy( )
		@but_submit.destroy( )
		@error.destroy( )
		@checkb_savetok.destroy( )
		@in_token.destroy( )
		@label.destroy( )

		@form.destroy( )

		@from = null
		@label = null
		@in_token = null
		@checkb_savetok = null
		@error = null
		@but_submit = null
		@but_exit = null


	# This function tries to login to the Discord server using the given
	# token.
	tryLogin: ( token, save_token ) ->
		self = this

		# We show a message to the user
		@error.content = "Logging in..."
		@app.screen.render( )

		client = new Discord.Client( )

		@app.prepareLogin client, token

		# We setup the ready callback
		client.on 'ready', @logincallback

		# We try to login
		client.login( @in_token.value ).then( ( s ) ->
			# The login has succeed.

			# If the user wants to save its token we save it
			if save_token
				self.app.setStoredtoken s

			# We notify the application the login is successful
			self.app.confirmLogin client, s
			self.destroyUI( )

		).catch ( err ) ->
			# If the login failed we tell the user about the error.
			self.error.content = "#{err}"
			self.app.screen.render( )


exports.LoginScreen = LoginScreen
