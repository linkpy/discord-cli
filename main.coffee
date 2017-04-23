
# Loading libs.
EventEmitter = require "events"

# Loading the script manager.
ScriptManager = require "./scriptmanager.js"


# Creating the hook system for allowing scripting for the starting stage.
# All hooks are available in hooklist.txt
Hooks = new EventEmitter()


# We loads all the scripts. You can add your own custom folder if you need it.
# The './' is obligatory, or require will throw an error.
try
	ScriptManager.LoadScripts "./scripts", Hooks

catch err

	console.error "Error while loading user's scripts : " + err
	console.error "Stack trace :"
	console.error err.stack
	process.exit 1


# We loads the application's main class and creates it. Everything will be done
# by it afterwards.
Application = require( "./app/application.js" ).Application
app = new Application Hooks
