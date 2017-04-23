// Generated by CoffeeScript 1.9.3
var Blessed, ChannelList, GuildList, Notifications;

Blessed = require("blessed");

GuildList = require("./guild-list.js").GuildList;

ChannelList = require("./channel-list.js").ChannelList;

Notifications = (function() {
  Notifications.LEFT = GuildList.WIDTH + ChannelList.WIDTH;

  Notifications.WIDTH = 80;

  Notifications.MAX_MESSAGES = 50;

  function Notifications(app, mainscreen) {
    this.app = app;
    this.mainscreen = mainscreen;
    this.storage = mainscreen.storage;
    this.last_guild_msgs = [];
    this.last_friend_msgs = [];
    this.last_msgs = [];
    this.box = null;
  }

  Notifications.prototype.setupUI = function() {
    return this.box = Blessed.box({
      left: Notifications.LEFT,
      top: 0,
      width: Notifications.WIDTH,
      height: 5,
      tags: true,
      style: {
        fg: "white",
        bg: "grey"
      }
    });
  };

  Notifications.prototype.setupEvents = function() {
    var self;
    self = this;
    this.storage.on("message-new", function(s, m, c) {
      if (m.author.id === self.app.client.user.id) {
        return;
      }
      if (c.id === self.storage.current_channel.id) {
        return;
      }
      if (c.guild != null) {
        if (self.storage.getGuildData(c.guild).muted) {
          return;
        }
      }
      if (self.storage.getChannelData(c).muted) {
        return;
      }
      self.last_msgs.push(m);
      if (c.guild != null) {
        self.last_guild_msgs.push(m);
      } else {
        self.last_friend_msgs.push(m);
      }
      self.update();
      return self.app.screen.render();
    });
    return this.storage.on("current-channel-changed", function() {
      self.removeReaded();
      self.update();
      return self.app.screen.render();
    });
  };

  Notifications.prototype.update = function() {
    var c, g, i, l, len, lfm, lgm, lines, lm, results;
    this.box.setContent("");
    if (this.last_msgs.length === 0) {
      return;
    }
    lines = [];
    lm = this.last_msgs[this.last_msgs.length - 1];
    lgm = null;
    lfm = null;
    if (this.last_guild_msgs.length > 0) {
      lgm = this.last_guild_msgs[this.last_guild_msgs.length - 1];
    }
    if (this.last_friend_msgs.length > 0) {
      lfm = this.last_friend_msgs[this.last_friend_msgs.length - 1];
    }
    lines[0] = "Last message by {cyan-fg}@" + lm.author.username + "{/}";
    if (lm.channel.guild != null) {
      g = lm.channel.guild;
      c = lm.channel;
      lines[0] += " on {red-fg}" + g.name + "{/} in {yellow-fg}#" + c.name + "{/}";
    }
    if ((lgm != null) && lgm.channel.guild.available) {
      g = lgm.channel.guild;
      c = lgm.channel;
      l = "  in servers : {cyan-fg}@" + lgm.author.username + "{/}";
      l += " on {red-fg}" + g.name + "{/} in {yellow-fg}#" + c.name + "{/}";
      lines.push(l);
    }
    if (lfm != null) {
      l = "  in friends : {cyan-fg}@" + lfm.author.username + "{/}";
      lines.push(l);
    }
    results = [];
    for (i = 0, len = lines.length; i < len; i++) {
      l = lines[i];
      results.push(this.box.pushLine(l));
    }
    return results;
  };

  Notifications.prototype.removeReaded = function() {
    var cc;
    cc = this.storage.current_channel;
    this.last_msgs = this.last_msgs.filter(function(a) {
      return a.channel.id !== cc.id;
    });
    this.last_guild_msgs = this.last_guild_msgs.filter(function(a) {
      return a.channel.id !== cc.id;
    });
    return this.last_friend_msgs = this.last_friend_msgs.filter(function(a) {
      return a.channel.id !== cc.id;
    });
  };

  return Notifications;

})();

exports.Notifications = Notifications;