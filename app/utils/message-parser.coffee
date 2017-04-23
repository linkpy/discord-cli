
Emphasize = require "emphasize"
Marked = require "marked"
Emoji = require "node-emoji"
EmojiRegex = require "emoji-regex"
Highlight = require "highlight.js"

entities = require( "html-entities" ).AllHtmlEntities

app = null
mesg = null

renderer = new Marked.Renderer( )
emoji_regex = EmojiRegex( )


replaceDiscordStuff = ( text ) ->

	text = entities.decode text

	text = text.replace /<(:\w+:)\d+>/g, (match, p) ->
		return p

	text = text.replace /:\w+:/g, (match) ->
		return "{green-fg}#{match}{/}"

	text = text.replace emoji_regex, (match) ->
		return "{green-fg}:#{Emoji.which match}:{/}"

	text = text.replace /@here|@everyone/g, (match) ->
		return "{yellow-fg}#{match}{/}"

	text = text.replace /<@(\d+)>/ig, (match, p1) ->

		users = mesg.mentions.users.array( )
		user = null

		for u in users
			if u.id == p1
				user = u
				break

		if user?
			return "{yellow-fg}@" + user.username + "{/}"

		return match

	text = text.replace /<#(\d+)>/ig, (match, p1) ->

		chans = mesg.mentions.channels.array( )
		chan = null

		for c in chans
			if c.id == p1
				chan = c
				break

		if chan?
			return "{yellow-fg}#" + chan.name + "{/}"

		return match

	text = text.replace /<@&(\d+)>/ig, (match, p1) ->

		roles = mesg.mentions.roles.array( )
		role = null

		for r in roles
			if r.id == p1
				role = r
				break

		if role?
			return "{#{role.hexColor}-fg}@" + role.name + "{/}"

		return match

	return text



renderer.code = ( code, lang ) ->

	if lang? and lang.length != 0
		if Highlight.getLanguage( lang )?
			code = Emphasize.highlight( lang, code ).value

	lines = code.split "\n"

	nwidth = 1

	if lines.length > 100
		nwidth = 3
	else if lines.length > 10
		nwidth = 2

	for i in [0 ... lines.length]

		n = ""
		if nwidth == 1
			n = String i+1

		if nwidth == 2
			if i < 10
				n = "0" + String i+1
			else
				n = String i+1

		if nwidth == 3
			if i < 10
				n = "00" + String i+1
			else if i < 100
				n = "00" + String i+1
			else
				n = String i+1

		lines[i] = " {#ff00ff-fg}#{n} |{/} #{lines[i]}"

	return "\n#{lines.join '\n'}{/}\n"

renderer.paragraph = ( text ) ->

	return replaceDiscordStuff( text ) + "\n"


renderer.strong = ( text ) ->
	text = replaceDiscordStuff( text )
	return "{white-fg}#{text}{/white-fg}"

renderer.em = ( text ) ->
	text = replaceDiscordStuff( text )
	return "{bold}#{text}{/bold}"

renderer.codespan = (code) ->
	return "{#FF00FF-fg}#{code}{/#FF00FF-fg}"

renderer.blockquote = ( text ) ->
	return ">" + replaceDiscordStuff( text )

renderer.link = ( href ) ->
	return "{blue-fg}#{href}{/blue-fg}"


exports.Parse = ( a, m ) ->

	app = a
	mesg = m

	ret = Marked m.content, {renderer: renderer}
	return entities.decode ret
