// Generated by CoffeeScript 1.9.3
var Command, Debug, GotoPreviousCommand,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Command = require("../command.js").Command;

Debug = require("../debug.js");

GotoPreviousCommand = (function(superClass) {
  extend(GotoPreviousCommand, superClass);

  function GotoPreviousCommand(app, mainscreen) {
    var self;
    GotoPreviousCommand.__super__.constructor.call(this, app, mainscreen, "goto-previous");
    this.storage = mainscreen.storage;
    this.stack = [];
    this.ignore_change = false;
    self = this;
    this.storage.on("current-channel-changed", function(s, c, last) {
      if (!self.ignore_change && (last != null)) {
        self.stack.push(last);
      }
      return self.ignore_change = false;
    });
  }

  GotoPreviousCommand.prototype.haveSuggestions = function(argidx) {
    return false;
  };

  GotoPreviousCommand.prototype.suggestions = function(arg, argidx) {
    return [];
  };

  GotoPreviousCommand.prototype.argumentName = function(argidx) {
    return "Max 0 argument";
  };

  GotoPreviousCommand.prototype.execute = function(args) {
    var c;
    if (this.stack.length === 0) {
      throw new Error("No previously visited channel.");
    }
    c = this.stack.pop();
    this.ignore_change = true;
    if (c.guild != null) {
      this.storage.selectGuild(c.guild, false);
    }
    return this.storage.selectChannel(c);
  };

  GotoPreviousCommand.prototype.getHelpText = function() {
    return ["{magenta-fg}/goto-previous{/}", "", "Go to the previously visited channel. Can be done multiple time.", "", "    {blue-fg}{bold}/goto-previous{/} : Go to the previously visited channel."];
  };

  return GotoPreviousCommand;

})(Command);

exports.Command = GotoPreviousCommand;