// Generated by CoffeeScript 1.9.3
var Command, ManualCommand, PAGES,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Command = require("../command.js").Command;

PAGES = {};

ManualCommand = (function(superClass) {
  extend(ManualCommand, superClass);

  function ManualCommand(app, mainscreen) {
    var page;
    ManualCommand.__super__.constructor.call(this, app, mainscreen, "man");
    this._suggestions = [];
    for (page in PAGES) {
      this._suggestions.push(page);
    }
  }

  ManualCommand.prototype.haveSuggestions = function(argidx) {
    return argidx === 0;
  };

  ManualCommand.prototype.suggestions = function(arg, argidx) {
    if (argidx === 0) {
      return this._suggestions.filter(function(a) {
        return a.startsWith(arg);
      });
    }
    return [];
  };

  ManualCommand.prototype.argumentName = function(argidx) {
    if (argidx === 0) {
      return "Page Name";
    }
    return "Max 1 argument";
  };

  ManualCommand.prototype.execute = function(args) {
    var input_panel, page;
    input_panel = this.mainscreen.input_panel;
    if (args.length > 0) {
      page = PAGES[args[0]];
      if (page == null) {
        throw new Error("Page '" + args[0] + "' doesn't exists.");
      }
      return input_panel.showCommandPanel(page);
    } else {
      throw new Error("Command 'man' needs one argument.");
    }
  };

  ManualCommand.prototype.getHelpText = function() {
    return ["{magenta-fg}/man page-name{/}", "", "Access to one of the page of the manual.", "", "{grey-fg}Note{/} : You can see the page list with {cyan-fg}'/man list'{/}"];
  };

  return ManualCommand;

})(Command);

PAGES["list"] = ["{#007F00-fg}{bold}List of manual pages :{/}", "  - {bold}input{/} - Page about the input box and the results panel.", "  - {bold}lists{/} - Page about the server and the channel lists."];

PAGES["input"] = ["{#007F00-fg}{bold}Input Box & Results Panel :{/}", "", "{bold}Note{/} : All the following shortcuts work when the input box has the", "    focus (when the cursor blink in it).", "", "{bold}Input State{/} : The input state is the text above the input box.", "    In its default state, it is 'Input'.", "", "{bold}When the input state is 'Input'{/} :", "    {red-fg}^X{/} : Toggle multiline edit.", "    {red-fg}ENTER{/} : Send the message.", "    Starting the line with a '{red-fg}/{/}' switch to command edit.", "", "{bold}When the input state is 'Input - Multiline ON'{/} :", "    {red-fg}^X{/} : Send the message and switch back to normal edit.", "    {red-fg}ENTER{/} : New line.", "    Deleting all the text will switch back to normal edit.", "", "{bold}When the input state is 'Input - Command'{/} :", "    {red-fg}ENTER{/} : Execute the command and switch back to normal edit.", "    {red-fg}UP | DOWN{/} : Select suggestion.", "    {red-fg}TAB{/} : Complete current element with the selected suggestion.", "    Deleting the initial '{red-fg}/{/}' character will switch back to ", "    normal edit.", "", "{bold}All the time{/} :", "    {red-fg}ESCAPE{/} : Unfocus the input text box.", "    {red-fg}^R{/} : Show / Hide the result panel (the white area where you", "    are reading right now)."];

PAGES["lists"] = [""];

exports.Command = ManualCommand;
