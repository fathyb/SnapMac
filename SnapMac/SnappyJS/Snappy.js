/*

###############################################################################################
#																							  #
#							Snappy.js, part of Snappy Project								  #
#																							  #
#					#################################################						  #
#																							  #
#								  2014 - Fathy Boundjadj									  #
#																							  #
###############################################################################################


*/



var kListByName    = 0,
	kListByStories = 1,
	
	kOrderAscending  = 0,
	kOrderDescending = 1,
	
	kStateLoading = 0,
	kStateLoaded  = 1;
	
window.addEventListener('error', function(e) {
	console.error(e);
});


var Snappy = new (function() {
	
	var __snapthis = this;
	
	this.cache = new Object();
	
	this.sendSnap = function(to, img) {
		SnapJS.sendSnap(to, img);
	}
	
	this.Updates = function(friends, snaps) {
		this.Conversations = snaps;
		this.Friends	   = friends;
		
		return this;
	}
	
	this.updateParser = function(result, callback) {
		if(result.error)
			return callback(result);
			
		Snappy.cache.username = result.updates_response.username;
		
		var friends		  = new Snappy.FriendList(result),
			conversations = new Snappy.ConversationList(result),
			updates		  = new Snappy.Updates(friends, conversations);
												
		callback(updates);
	}
	
	this.getKeychain = function(callback) {
		SnapJS.getKeychain(callback);
	}
	
	this._loginCallback = null;
	this.login = function(username, password, callback) {
		SnapJS.login(username, password, function(r) {
			if(r.error)
				callback(r);
				
			else
				Snappy.getUpdates(function(r) {
					callback(r);
				}, r.updates);
		});
	}
	this.getUpdates = function(callback, updates) {
		if(!updates)
			SnapJS.getUpdates(function(r) {
				Snappy.updateParser(r, callback);
			});
		else
			this.updateParser(updates, callback);
	}
	
	
	this.Friend = function(raw) {
		this.best 		 = false;
		this.name 		 = raw.name;
		this.isMe		 = this.name == Snappy.cache.username;
		this.displayName = raw.display || this.name;
		this.stories	 = new Array();
		this.isEvent	 = !!raw.is_shared_story;
		
		this.rename = function(name, callback) {
			SnapJS.renameFriend(this.name, "display", name, function(r) {
				if(callback)
					callback(r);
			});
		}
		
		if(this.isEvent) {
			this.expiration = new Snappy.SnappyDate(raw.expiration);
			this.place = raw.venue;
			this.mapsURL = "https://www.google.fr/maps/place/"+escape(this.place);
		}
		this.showInMaps = function() {
			if(this.mapsURL)
				SnapJS.openURL(this.mapsURL);
		}
		
		this.addStories	 = function(stories) {
			var story;
			
			for(var i in stories) {
				story = new Snappy.Story(stories[i]);
				
				story.friend = this;
				
				this.stories.push(story);
			}
		}
		
		this.block = function() {
			this.update({
				action: "block"
			});
		}
		this.unblock = function() {
			this.update({
				action: "unblock"
			});
		}
		this.deleteFriend = function() {
			this.update({
				action: "delete"
			});
		}
		this.rename = function(name) {
			this.update({
				action: "dislay",
				display: name
			});
			this.displayName = name;
		}
		this.update = function(fields) {
			SnapJS.updateFriend(this.name, fields, function(result) {
				
			});
		}
		return this;
	}
	
	this.FriendList = function(updates) {
	
		this.friends 	  = new Array();
		this.best_friends = new Array();
		
		this.friendByName = function(name) {
			var friend, i;
			
			for(i in this.friends) {
				friend = this.friends[i];
				
				if(friend.name.toLowerCase() == name.toLowerCase())
					return friend;
			}
		}
		
		this.getOnlyFriends = function(opts) {
			
			if(!opts)
				opts = {}
			
			var dOpts = {
				showEvents: false,
				hasStories: true,
				list: kListByName,
				order: kOrderAscending
			};
			
			for(var k in dOpts)
				if(!opts[k])
					opts[k] = dOpts[k]
			
			var arr	    = new Array(),
				friends = this.listFriends(opts.list, opts.order),
				friend  = null;
			
			for(var i in this.friends) {
				friend = this.friends[i];
				
					
				if(opts.showEvents && friend.isEvent) {
					arr.push(friend);
					continue;
				}
				if(opts.hasStories && friend.stories.length) {
					arr.push(friend);
					continue;
				}
			}
			
			return arr;
		}
		this.listFriends = function(by, order) {
			by = (by ? by : kListByName);
			order = (order ? order : kOrderAscending)
		
			var dupArr = this.friends;
			
			dupArr.sort(function(a, b) {
				var r;
				
				switch(by) {
					case kListByName:
						r = a.name.toLowerCase().localeCompare(b.name.toLowerCase());
						break;
						
					case kListByStories:
						r =  (a.stories.length < b.stories.length ? -1 : 1);
						break;
				}
				
				return r;
			});
			
			if(order == kOrderDescending)
				dupArr.reverse();
				
			return dupArr;
		}
		
		
		this.setStories = function(data) {
			var fStories = data.friend_stories,
				friend, stories;
			
			for(var i in fStories) {
				stories = fStories[i];
				
				if(!stories.username)
					continue;
				
				friend = this.friendByName(stories.username);
				if(friend)
					friend.addStories(stories.stories);
			}
			
			if(data.my_stories.length) {
				var me = this.friendByName(Snappy.cache.username);
				me.addStories(data.my_stories);
			}
		}
		
		this.searchFriend = function(str) {
			str =  str.toLowerCase();
			var friends = [];
			for(var i in this.friends) {
				var friend = this.friends[i];
				
				if(~(friend.name.toLowerCase().indexOf(str)) || ~(friend.displayName.toLowerCase().indexOf(str)))
					friends.push(friend);
			}
			
			return friends;
		}
		this.addFriend = function(friend) {
			this.friends.push(friend);
		}
		
		this.addBest = function(bFriend) {
			var friend  	= this.friendByName(bFriend);
				friend.best = true;
			this.best_friends.push(friend);
		}
		
		
		var jsonFriends = updates.updates_response.friends,
				 friend;
			
		for(var i in jsonFriends) {
			friend = new Snappy.Friend(jsonFriends[i]);
			this.addFriend(friend);
		}
		
		this.setStories(updates.stories_response);
		
		Snappy.cache.friends = this;
		
		return this;
	}
	

	this.Story = function(raw) {
		if(!raw.story)
			return false;
	
		var story 	= raw.story,
			iv 		= story.media_iv,
			key		= story.media_key,
			id		= story.media_id;
		
		if(raw.story_extras) {
			this.screenshotCount = raw.story_extras.screenshot_count;
			this.viewCount		 = raw.story_extras.view_count;
		}
		if(raw.story_notes) {
			this.views = new Object();
			var note, i;
			
			for(i in raw.story_notes) {
				note = raw.story_notes[i];
				this.views[note.viewer] = {
					date		  : new Snappy.SnappyDate(note.timestamp),
					screenshotted : note.screenshotted
				}
			}
		}
		
		this.viewed    = raw.viewed;
		this.state	   = "decrypt";
		this.id		   = story.media_id;
		this.duration  = Math.round(story.time);
		this.date	   = new Snappy.SnappyDate(story.timestamp);
		this.timeLeft  = raw.time_left;
		this.mediaType = new Snappy.MediaType(story.media_type);
		
		this.show = function() {
			SnapJS.showMedia(this.id, this.duration);
		}
		this.changeBlocks = new Array();
		
		this.change = function(fn) {
			if(this.stated == "loaded") {
				fn(this);
				return;
			}
				
			if(!fn) {
				for(var i in this.changeBlocks)
					this.changeBlocks[i](this);
				this.changeBlocks = new Array();
			}
			else
				this.changeBlocks.push(fn);
		}
		
		this.load = function() {
			var _this = this;
			SnapJS.getStory(id, key, iv, function(result) {
				if(result.error) {
					console.log(result.error);
				}
				else {
					_this.state = "loaded";
					_this.image = result.thumb;
					_this.change();
				}
			});
		}
		return this;
		
	}
	this.ConversationList = function(updates) {
		this.conversations = new Array();
		
		for(var i in updates.conversations_response)
			this.conversations.push(
				new Snappy.Conversation(updates.conversations_response[i])
			);
	}
	this.Conversation = function(conversation) {
		this.snaps = new Array();
		this.messages = new Array();
		this.users = new Array();
		this.id = conversation.id;
		this.lastInteraction = new Snappy.SnappyDate(conversation.last_interaction_ts);
		this.snapsUnread = conversation.pending_received_snaps.length;
		this.msgUnread = conversation.pending_chats_for.length;
		
		this.duration = 0;
		
		var user,
			iremovedclone = false;
		for(var i in conversation.participants) {
			user = conversation.participants[i];
			
			if(user == Snappy.cache.username && !iremovedclone) {
				iremovedclone = true;
				continue;
			}
				
			var friend = Snappy.cache.friends.friendByName(user);
			if(friend)
				this.users[this.users.length] = friend.displayName;
			else
				this.users[this.users.length] = user;
		}
		
		var messages = conversation.conversation_messages.messages;
		
		for(var i in messages) {
			var message = messages[i],
				snap = message.snap,
				chat_msg = message.chat_message;
				
			if(snap) {
				snap = new Snappy.Snap(snap);
				this.snaps.push(snap);
				if(snap.received)
					this.duration += snap.timer;
			}
			else if(chat_msg)
				this.messages.push(chat_msg);
		}
			
	}
	
	this.Snap = function(raw) {
		this.received 	= !!raw.sn;
		this.sent		=  !raw.sn;
		this.user		= this.received ? raw.sn 	: raw.rp;
		this.sender		= this.received ? this.user : "me";
		this.dest 		= this.sent 	? this.user : "me";
		
		this.id			= raw.id;
		this.date		= new Snappy.SnappyDate(raw.ts);
		this.mediaType 	= new Snappy.MediaType(raw.m);
		this.state		= kStateLoading;
		this.url		= null;
		this.timer		= raw.t || 0;
		this.read 		= !!this.timer;
		
		this.show = function() {
			SnapJS.showMedia(this.id, this.timer);
		}		
		
		this.changeBlocks = new Array();
		
		this.showInFinder = function() {
			SnapJS.showInFinder(this.urls.filePath);
		}
		this.change = function(fn) {
			if(!fn) {
				for(var i in this.changeBlocks) 
					this.changeBlocks[i](this);
			}
			else {
				this.changeBlocks.push(fn);
			}
		}
		this.load = function() {
			var _this = this;
			SnapJS.getSnap(this.id, function(result) {
				if(!result || result.error) {
					return console.error("Error snap");
				}
				_this.urls = result;
				_this.url = result.thumb;
				_this.change();
			});
		}
		
		this.load();
		
		return this;
	}
	
	this.SnappyDate = function(ts) {
		
		this.date = new Date(ts);
			
		this.timeSince = function() {
			
			var seconds  = Math.floor((new Date() - this.date) / 1000);
			if(seconds < 0)
				seconds = seconds * -1;
				
			var interval = Math.floor(seconds / 31536000);
			
			if(interval > 1)
		        return interval + " "+loc("years");
		        
		    interval = Math.floor(seconds / 2592000);
		    if(interval > 1)
		        return interval + " "+loc("months");
		        
		    interval = Math.floor(seconds / 86400);
		    if(interval > 1)
		        return interval +  " "+loc("days");
		        
		    interval = Math.floor(seconds / 3600);
		    if(interval > 1)
		        return interval + " "+loc("hours");
		        
		    interval = Math.floor(seconds / 60);
		    if(interval > 1)
		        return interval + " "+loc("minutes");
		        
		    return Math.floor(seconds) + " secondes";
		}
		
		return this;
	}
	this.MediaType = function(id) {
		function a(b) {
			return !!b[id];
		}
		this.id	 = id;
		
		var mask = {
					Video: [0, 1, 1, 0, 0, 1, 1],
					Audio: [0, 1, 0, 0, 0, 1, 0],
					Image: [1, 0, 0, 0, 1, 0, 0],
			FriendRequest: [0, 0, 0, 1, 1, 1, 1]
		}
		
		for(var k in mask)
			this["is"+k] = a(mask[k]);
		
		return this;
	}
	
	this.tmp = {
		SnapBack: {}
	}

	this.rightClick = new Function();
	this.search = new Function();
	
	return this; 
})();

function SnappySearchHandler(str) {
	return Snappy.search(str);
}
function SnappyRClickHandler(element) {
	return Snappy.rightClick(element);
}

function loc(str) {
	var lStr = SnapJS.locale(str);
	
	if(arguments.length > 1)
		for(var i = 1; lStr.search("%@") != -1; i++)
			lStr = lStr.replace("%@", arguments[i] || "");
		
	return lStr;
}

