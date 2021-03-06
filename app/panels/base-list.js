// Generated by CoffeeScript 1.9.3
var BaseList, Blessed, Debug;

Blessed = require("blessed");

Debug = require('../debug.js');

BaseList = (function() {
  function BaseList(app, mainscreen) {
    this.app = app;
    this.mainscreen = mainscreen;
    this.storage = mainscreen.storage;
    this.list = [];
    this.box = null;
    this.mute = null;
    this.position = {
      left: 0,
      top: 0,
      width: 0
    };
  }

  BaseList.prototype.setupUI = function() {
    this.box = Blessed.list({
      mouse: true,
      keys: true,
      tags: true,
      items: [],
      left: this.position.left,
      top: this.position.top,
      width: this.position.width,
      height: "100%-" + this.position.top,
      padding: {
        top: 3,
        left: 1,
        right: 1
      },
      style: {
        bg: "grey",
        item: {
          fg: "white",
          bg: "grey"
        },
        selected: {
          fg: "cyan",
          bg: "grey"
        },
        focus: {
          item: {
            fg: "yellow"
          }
        }
      }
    });
    return this.mute = Blessed.button({
      parent: this.box,
      clickable: true,
      keyable: false,
      top: -2,
      left: 1,
      width: "100%-4",
      height: 1,
      content: "Toggle Muted",
      align: "center",
      style: {
        fg: "black",
        bg: "white",
        hover: {
          fg: "black",
          bg: "red"
        },
        focus: {
          fg: "red",
          bg: "black"
        }
      }
    });
  };

  BaseList.prototype.setupEvents = function() {
    var self;
    self = this;
    this.mute.on("click", function(m) {
      return self.mute.press();
    });
    return this.mute.on("press", function() {
      var item;
      item = self.list[self.box.selected];
      if (item != null) {
        return self.muteSelected(item);
      }
    });
  };

  BaseList.prototype.destroyUI = function() {
    this.box.destroy();
    return this.box = null;
  };

  BaseList.prototype.populate = function(entries) {
    var entry, item, j, len, results;
    results = [];
    for (j = 0, len = entries.length; j < len; j++) {
      entry = entries[j];
      item = this.createItem(entry);
      this.list.push(item);
      results.push(this.box.addItem(item.text));
    }
    return results;
  };

  BaseList.prototype.repopulate = function(entries) {
    var oldSelected;
    this.list = [];
    oldSelected = this.box.selected;
    this.box.clearItems();
    this.populate(entries);
    if (oldSelected <= this.list.length) {
      return this.box.select(oldSelected);
    }
  };

  BaseList.prototype.update = function() {
    var i, item, j, len, ref, results;
    i = 0;
    ref = this.list;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      item = ref[j];
      item.updateText();
      this.box.setItem(i, item.text);
      results.push(i += 1);
    }
    return results;
  };

  BaseList.prototype.createItem = function(entry) {
    throw new Error("Abstract function not implemented.");
  };

  BaseList.prototype.muteSelected = function(item) {
    throw new Error("Abstract function not implemented.");
  };

  return BaseList;

})();

exports.BaseList = BaseList;
