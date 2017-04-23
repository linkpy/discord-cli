// Generated by CoffeeScript 1.9.3
var Blessed, ChannelList, Debug, GuildList, MessageEntry, MessagePanel, MessagePopup;

Blessed = require("blessed");

Debug = require('../debug.js');

GuildList = require("./guild-list.js").GuildList;

ChannelList = require("./channel-list.js").ChannelList;

MessageEntry = require("./message-entry.js").MessageEntry;

MessagePopup = require("./message-popup.js").MessagePopup;

MessagePanel = (function() {
  MessagePanel.LEFT = GuildList.WIDTH + ChannelList.WIDTH;

  function MessagePanel(app, mainscreen) {
    this.app = app;
    this.mainscreen = mainscreen;
    this.storage = mainscreen.storage;
    this.entries = [];
    this.box = null;
    this.popup = new MessagePopup(app, mainscreen);
    this.selected = -1;
    this.offset = 0;
  }

  MessagePanel.prototype.setupUI = function() {
    this.box = Blessed.box({
      left: MessagePanel.LEFT,
      top: 6,
      width: "100%-" + MessagePanel.LEFT,
      height: "100%-10",
      style: {
        bg: "black"
      }
    });
    return this.popup.setupUI();
  };

  MessagePanel.prototype.setupEvents = function() {
    var self;
    self = this;
    this.storage.on("current-channel-changed", function(s, c) {
      self.selected = -1;
      self.repopulate(s.current_messages);
      return self.app.screen.render();
    });
    this.storage.on("current-messages-changed", function(s) {
      self.repopulate(s.current_messages);
      return self.app.screen.render();
    });
    return this.popup.setupEvents();
  };

  MessagePanel.prototype.populate = function(entries) {
    var e, entry, j, k, len, len1, ref, results, self, y;
    entries.sort(function(a, b) {
      if (a.createdTimestamp < b.createdTimestamp) {
        return -1;
      }
      if (a.createdTimestamp > b.createdTimestamp) {
        return 1;
      }
      return 0;
    });
    self = this;
    y = 0;
    for (j = 0, len = entries.length; j < len; j++) {
      entry = entries[j];
      e = new MessageEntry(this.app, this.mainscreen, this, entry);
      e.index = this.entries.length;
      this.entries.push(e);
      e.setupUI(y);
      e.setupEvents();
      y += e.getHeight();
      e.on("selected", function(e) {
        return self.select(e);
      });
    }
    if (this.selected > this.entries.length - 1) {
      this.selected = -1;
    }
    if (this.selected >= 0) {
      this.entries[this.selected].select();
    }
    if (y > this.box.height) {
      this.offset = -(this.box.height - y);
      ref = this.entries;
      results = [];
      for (k = 0, len1 = ref.length; k < len1; k++) {
        entry = ref[k];
        entry.applyOffset(this.offset);
        if (entry.getTop() + entry.getHeight() < 0) {
          results.push(entry.hide());
        } else {
          results.push(void 0);
        }
      }
      return results;
    }
  };

  MessagePanel.prototype.repopulate = function(entries) {
    var entry, j, len, ref;
    ref = this.entries;
    for (j = 0, len = ref.length; j < len; j++) {
      entry = ref[j];
      entry.destroyUI();
    }
    this.entries = [];
    return this.populate(entries);
  };

  MessagePanel.prototype.select = function(entry) {
    if (entry.index === this.selected) {
      this.popup.updateContent(entry.message);
      this.popup.show();
    } else {
      if (this.selected > 0) {
        this.entries[this.selected].unselect();
      }
      this.selected = entry.index;
      entry.select();
    }
    return this.app.screen.render();
  };

  MessagePanel.prototype.selectIdx = function(i) {
    if (this.selected > 0) {
      this.entries[this.selected].unselect();
    }
    if (i < 0) {
      i = 0;
    }
    if (i >= this.entries.length) {
      i = this.entries.length - 1;
    }
    this.selected = i;
    this.entries[i].select();
    return this.app.screen.render();
  };

  MessagePanel.prototype.up = function() {
    if (this.selected > 0) {
      return this.selectIdx(this.selected - 1);
    } else {
      return this.selectIdx(this.entries.length - 1);
    }
  };

  MessagePanel.prototype.down = function() {
    if (this.selected > 0) {
      return this.selectIdx(this.selected + 1);
    }
  };

  return MessagePanel;

})();

exports.MessagePanel = MessagePanel;
