// Generated by CoffeeScript 1.9.3
var Debug, EventEmitter, Storage,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

EventEmitter = require("events");

Debug = require("./debug.js");

Storage = (function(superClass) {
  extend(Storage, superClass);

  Storage.INITIAL_MESSAGE_FETCH = 50;

  Storage.MAX_MESSAGES = Storage.INITIAL_MESSAGE_FETCH * 2;

  function Storage(app) {
    Storage.__super__.constructor.call(this);
    this.app = app;
    this.client = app.client;
    this.users = {};
    this.guilds = [];
    this.channels = [];
    this.messages = {};
    this.dmchannels = [];
    this.dmchannels_user = {};
    this.users_data = {};
    this.guilds_data = {};
    this.channels_data = {};
    this.users_states = {};
    this.guilds_states = {};
    this.channels_states = {};
    this.current_guild = null;
    this.current_channels = null;
    this.current_messages = null;
  }

  Storage.prototype.fill = function() {
    var cdata, chan, currentchan, gdata, guild, j, k, l, len, len1, len2, ref, ref1, ref2, self;
    self = this;
    this.guilds = this.client.guilds.array();
    ref = this.guilds;
    for (j = 0, len = ref.length; j < len; j++) {
      guild = ref[j];
      if (!guild.available) {
        continue;
      }
      this.channels = this.channels.concat(guild.channels.array().filter(function(c) {
        return self.app.filterChannel(c);
      }));
      gdata = this.app.getGuildOptions(guild.id);
      this.guilds_data[guild.id] = gdata;
    }
    ref1 = this.channels;
    for (k = 0, len1 = ref1.length; k < len1; k++) {
      chan = ref1[k];
      if (!this.app.filterChannel(chan)) {
        continue;
      }
      this.messages[chan.id] = [];
      cdata = this.app.getChannelOptions(chan.id);
      this.channels_data[chan.id] = cdata;
    }
    ref2 = this.getDMChannels();
    for (l = 0, len2 = ref2.length; l < len2; l++) {
      chan = ref2[l];
      this.dmchannels.push(chan);
      this.messages[chan.id] = [];
      cdata = this.app.getChannelOptions(chan.id);
      this.channels_data[chan.id] = cdata;
    }
    this.current_guild = this.guilds[0];
    currentchan = this.getCurrentChannels()[0];
    if (currentchan != null) {
      return this.selectChannel(currentchan);
    }
  };

  Storage.prototype.setupEvents = function() {
    var self;
    self = this;
    this.client.on("guildCreate", function(g) {
      return self.storeGuild(g);
    });
    this.client.on("guildDelete", function(g) {
      return self.removeGuild(g);
    });
    this.client.on("guildUpdate", function(oldg, newg) {
      return self.updateGuild(oldg, newg);
    });
    this.client.on("channelCreate", function(c) {
      var cdata;
      if (!self.app.filterChannel(c)) {
        return;
      }
      if (self.channels_data[c.id] == null) {
        cdata = self.app.getChannelOptions(c.id);
        self.channels_data[c.id] = cdata;
      }
      if (c.type === "text") {
        self.channels.push(c);
      } else {
        self.dmchannels.push(c);
      }
      self.messages[c.id] = [];
      return self.emit("channel-new", self, c);
    });
    this.client.on("channelDelete", function(c) {
      var i, j, ref, results;
      results = [];
      for (i = j = 0, ref = self.channels.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        if (self.channels[i].id === c.id) {
          self.emit("channel-remove", self, c);
          self.channels.splice(i, 1);
          delete self.messages[c.id];
          break;
        } else {
          results.push(void 0);
        }
      }
      return results;
    });
    this.client.on("channelUpdate", function(oldc, newc) {
      var i, j, ref, results;
      results = [];
      for (i = j = 0, ref = self.channels.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        if (self.channels[i].id === oldc) {
          self.channels[i] = newc;
          self.emit("channel-update", self, oldc, newc);
          break;
        } else {
          results.push(void 0);
        }
      }
      return results;
    });
    this.client.on("channelPinsUpdate", function(c) {
      var mesgs;
      mesgs = self.messages[c.id];
      return c.fetchPinnedMessages().then(function(ms) {
        var i, j, k, len, m, ref, ref1;
        for (i = j = ref = mesgs.length; j > 0; i = j += -1) {
          mesgs[i].pinned = false;
          ref1 = ms.array();
          for (k = 0, len = ref1.length; k < len; k++) {
            m = ref1[k];
            if (mesgs[i].id === m.id) {
              mesgs[i].pinned = true;
            }
          }
        }
        if (c.id === self.current_channel.id) {
          return self.emit("current-messages-changed", self);
        }
      })["catch"](function(err) {});
    });
    this.client.on("message", function(m) {
      var c, mesgs, us;
      c = m.channel;
      mesgs = self.messages[c.id];
      if (mesgs == null) {
        self.messages[c.id] = [];
        mesgs = self.messages[c.id];
      }
      mesgs.push(m);
      if (mesgs.length > Storage.MAX_MESSAGES) {
        mesgs.splice(0, mesgs.length - Storage.MAX_MESSAGES);
      }
      us = self.getUserStates(m.author);
      us.lastMesgsTimestamps[c.id] = m.createdTimestamp;
      self.setUserStates(m.author, us);
      self.setUnread(m);
      self.emit("message-new", self, m, c);
      if (c.id === self.current_channel.id) {
        return self.emit("current-messages-changed", self);
      }
    });
    this.client.on("messageDelete", function(m) {
      var c, i, j, msgs, ref, results;
      c = m.channel;
      if (self.messages[c.id] == null) {
        return;
      }
      msgs = self.messages[c.id];
      results = [];
      for (i = j = ref = msgs.length - 1; j > 0; i = j += -1) {
        if (msgs[i].id === m.id) {
          self.emit("message-remove", self, m, c);
          msgs.splice(i, 1);
          if (c.id === self.current_channel.id) {
            self.emit("current-messages-changed", self);
          }
          break;
        } else {
          results.push(void 0);
        }
      }
      return results;
    });
    return this.client.on("messageUpdate", function(oldm, newm) {
      var c, i, j, msgs, ref, results;
      c = oldm.channel;
      if (self.messages[c.id] == null) {
        return;
      }
      msgs = self.messages[c.id];
      results = [];
      for (i = j = ref = msgs.length - 1; j > 0; i = j += -1) {
        if (msgs[i].id === oldm.id) {
          msgs[i] = newm;
          self.emit("message-update", self, oldm, newm, c);
          if (c.id === self.current_channel.id) {
            results.push(self.emit("current-messages-changed", self));
          } else {
            results.push(void 0);
          }
        } else {
          results.push(void 0);
        }
      }
      return results;
    });
  };

  Storage.prototype.storeGuild = function(g) {
    var cdata, chan, j, len, ref, self;
    self = this;
    this.guilds.push(g);
    if (!g.available) {
      return;
    }
    this.channels.concat(g.channels);
    ref = g.channels.array();
    for (j = 0, len = ref.length; j < len; j++) {
      chan = ref[j];
      this.messages[chan.id] = [];
      if (this.channels_data[chan.id] == null) {
        cdata = this.app.getChannelOptions(chan.id);
        this.channels_data[chan.id] = cdata;
      }
      this.emit("channel-new", self, chan);
    }
    this.emit("guild-new", self, g);
    this.emit("guilds-changed", self);
    return this.emit("channels-changed", self);
  };

  Storage.prototype.removeGuild = function(g) {
    var c, i, j, k, l, len, n, ref, ref1, ref2, ref3, tmp_removelist;
    for (i = j = 0, ref = this.guilds.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      if (this.guilds[i].id === g.id) {
        this.guilds.splice(i, 1);
        break;
      }
    }
    tmp_removelist = [];
    for (i = k = 0, ref1 = this.channels.length; 0 <= ref1 ? k < ref1 : k > ref1; i = 0 <= ref1 ? ++k : --k) {
      ref2 = g.channels.array();
      for (l = 0, len = ref2.length; l < len; l++) {
        c = ref2[l];
        if (this.channels[i].id === c.id) {
          this.emit("channel-remove", self, c);
          tmp_removelist.push(i);
          delete this.messages[c.id];
        }
      }
    }
    for (i = n = 0, ref3 = tmp_removelist.length; 0 <= ref3 ? n < ref3 : n > ref3; i = 0 <= ref3 ? ++n : --n) {
      this.channels.splice(tmp_removelist[i] - i, 1);
    }
    this.emit("guild-remove", self, g);
    this.emit("guilds-changed", self);
    return this.emit("channels-changed", self);
  };

  Storage.prototype.updateGuild = function(oldg, newg) {
    var i, j, ref, results;
    results = [];
    for (i = j = 0, ref = this.guilds.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
      if (this.guilds[i].id === oldg) {
        this.guilds[i] = newg;
        this.emit("guild-update", self, oldg, newg);
        this.emit("guilds-changed", self);
        break;
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  Storage.prototype.selectGuild = function(guild, emit) {
    if ((this.current_guild != null) && (guild != null) && guild.id === this.current_guild.id) {
      return;
    }
    this.current_guild = guild;
    this.selectChannel(this.getCurrentChannels()[0], emit);
    this.emit("current-guild-changed", this, guild);
    return this.emit("channels-changed", this);
  };

  Storage.prototype.selectChannel = function(channel, emit) {
    var last, self;
    if ((emit != null) && !emit) {
      return;
    }
    if ((this.current_channel != null) && this.current_channel.id === channel.id) {
      return;
    }
    if (this.messages[channel.id] == null) {
      this.messages[channel.id] = [];
    }
    last = this.current_channel;
    if (this.messages[channel.id].length < Storage.INITIAL_MESSAGE_FETCH) {
      self = this;
      channel.fetchMessages({
        limit: Storage.INITIAL_MESSAGE_FETCH
      }).then(function(m) {
        var j, len, ref, us;
        self.messages[channel.id] = m.array();
        ref = self.messages[channel.id];
        for (j = 0, len = ref.length; j < len; j++) {
          m = ref[j];
          us = self.getUserStates(m.author);
          us.lastMesgsTimestamps[channel.id] = m.createdTimestamp;
          self.setUserStates(m.author, us);
        }
        if (self.current_channel.id === channel.id) {
          self.current_messages = self.messages[channel.id];
          self.emit("current-messages-changed", self);
        }
        return self.emit("messages-changed", self);
      })["catch"](function(err) {
        throw err;
      });
    }
    this.current_channel = channel;
    this.current_messages = this.messages[channel.id];
    this.setRead(channel);
    this.emit("current-channel-changed", this, channel, last);
    this.emit("current-messages-changed", this);
    return this.emit("messages-changed", this);
  };

  Storage.prototype.setUnread = function(mesg) {
    var chan, cstates, gstates, guild;
    chan = mesg.channel;
    guild = mesg.guild;
    if (chan.id === this.current_channel.id) {
      return;
    }
    cstates = this.getChannelStates(chan);
    if (cstates.unreaded) {
      return;
    }
    cstates.unreaded = true;
    this.setChannelStates(chan, cstates);
    if (guild != null) {
      gstates = this.getGuildStates(guild);
      gstates.unreaded += 1;
      return this.setGuildStates(guild, gstates);
    }
  };

  Storage.prototype.setRead = function(chan) {
    var cstates, gstates, guild;
    cstates = this.getChannelStates(chan);
    if (!cstates.unreaded) {
      return;
    }
    cstates.unreaded = false;
    this.setChannelStates(chan);
    guild = chan.guild;
    if (guild != null) {
      gstates = this.getGuildStates(guild);
      gstates.unreaded -= 1;
      return this.setGuildStates(guild, gstates);
    }
  };

  Storage.prototype.getCurrentChannels = function() {
    var self;
    if (this.current_guild == null) {
      return this.dmchannels;
    }
    if (!this.current_guild.available) {
      return [];
    }
    self = this;
    return this.current_guild.channels.array().filter(function(chan) {
      return self.app.filterChannel(chan);
    });
  };

  Storage.prototype.getDMChannels = function() {
    var friend, friends, j, len, list, user;
    user = this.client.user;
    if (user == null) {
      return [];
    }
    friends = user.friends.array();
    list = [];
    for (j = 0, len = friends.length; j < len; j++) {
      friend = friends[j];
      if (friend.dmChannel != null) {
        this.dmchannels_user[friend.dmChannel.id] = friend;
        list.push(friend.dmChannel);
      }
    }
    return list;
  };

  Storage.prototype.sortDMChannels = function(list) {
    var self;
    self = this;
    return list.sort(function(a, b) {
      var lastAT, lastBT, mesgsA, mesgsB;
      mesgsA = self.messages[a.id];
      mesgsB = self.messages[b.id];
      if ((mesgsA != null) && (typeof msgsB === "undefined" || msgsB === null)) {
        return 1;
      }
      if ((mesgsA == null) && (typeof msgsB !== "undefined" && msgsB !== null)) {
        return -1;
      }
      if ((mesgsA == null) && (mesgsB == null)) {
        return 0;
      }
      lastAT = mesgsA[mesgsA.length - 1].createdTimestamp;
      lastBT = mesgsB[mesgsB.length - 1].createdTimestamp;
      if (lastAT > lastBT) {
        return 1;
      }
      if (lastAT < lastBT) {
        return -1;
      }
      return 0;
    });
  };

  Storage.prototype.getLastActiveUsers = function(channel) {
    var members, self;
    if (channel.guild == null) {
      return [];
    }
    self = this;
    members = channel.members.array();
    members.sort(function(a, b) {
      var as, bs;
      as = self.getUserStates(a).lastMesgsTimestamps[channel.id] || 0;
      bs = self.getUserStates(b).lastMesgsTimestamps[channel.id] || 0;
      if (as > bs) {
        return 1;
      }
      if (as < bs) {
        return -1;
      }
      return 0;
    });
    return members;
  };

  Storage.prototype.getUserData = function(user) {
    if (this.users_data[user.id] == null) {
      this.users_data[user.id] = {
        muted: false
      };
    }
    return this.users_data[user.id];
  };

  Storage.prototype.getGuildData = function(guild) {
    if (this.guilds_data[guild.id] == null) {
      this.guilds_data[guild.id] = this.app.getGuildOptions(guild.id);
    }
    if (this.guilds_data[guild.id] == null) {
      this.guilds_data[guild.id] = {
        muted: false
      };
    }
    return this.guilds_data[guild.id];
  };

  Storage.prototype.getChannelData = function(channel) {
    if (this.channels_data[channel.id] == null) {
      this.channels_data[channel.id] = this.app.getChannelOptions(channel.id);
    }
    if (this.channels_data[channel.id] == null) {
      this.channels_data[channel.id] = {
        muted: false
      };
    }
    return this.channels_data[channel.id];
  };

  Storage.prototype.setUserData = function(user, data) {
    return this.users_data[user.id] = data;
  };

  Storage.prototype.setGuildData = function(guild, data) {
    this.guilds_data[guild.id] = data;
    return this.emit("guild-states-changed", this, guild);
  };

  Storage.prototype.setChannelData = function(channel, data) {
    this.channels_data[channel.id] = data;
    return this.emit("channel-states-changed", this, channel);
  };

  Storage.prototype.getUserStates = function(user) {
    if (this.users_states[user.id] == null) {
      this.users_states[user.id] = {
        lastMesgsTimestamps: {}
      };
    }
    return this.users_states[user.id];
  };

  Storage.prototype.getGuildStates = function(guild) {
    if (this.guilds_states[guild.id] == null) {
      this.guilds_states[guild.id] = {
        unreaded: 0
      };
    }
    return this.guilds_states[guild.id];
  };

  Storage.prototype.getChannelStates = function(channel) {
    if (this.channels_states[channel.id] == null) {
      this.channels_states[channel.id] = {
        unreaded: false
      };
    }
    return this.channels_states[channel.id];
  };

  Storage.prototype.setUserStates = function(user, states) {
    return this.users_states[user.id] = states;
  };

  Storage.prototype.setGuildStates = function(guild, states) {
    this.guilds_states[guild.id] = states;
    return this.emit("guild-states-changed", this, guild);
  };

  Storage.prototype.setChannelStates = function(channel, states) {
    this.channels_states[channel.id] = states;
    return this.emit("channel-states-changed", this, channel);
  };

  return Storage;

})(EventEmitter);

exports.Storage = Storage;