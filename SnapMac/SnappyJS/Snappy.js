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
			
		console.log(result);
		
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
		this.displayName = raw.display || this.name;
		this.stories	 = [];
		
		this.changeBlocks = [];
		this.change 	  = function(fn) {
			if(!fn)
				for(var i in this.changeBlocks)
					this.changeBlocks[i](this);
					
			else if(typeof fn == "function")
				this.changeBlocks.push(fn);
		}
		
		this.addStories	 = function(stories) {
			var story;
			
			for(var i in stories) {
				story = new Snappy.Story(stories[i]);
				
				story.friend = this;
				story.change(function(story) {
					story.friend.change();
				});
				
				this.stories.push(story);
			}
			this.change();
		}
		
		return this;
	}
	
	this.FriendList = function(updates) {
	
		this.friends 	  = [];
		this.best_friends = [];
		
		this.friendByName = function(name) {
			var friend, i;
			
			for(i in this.friends) {
				friend = this.friends[i];
				
				if(friend.name.toLowerCase() == name.toLowerCase())
					return friend;
			}
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
		
		
		this.attachStories = function(data) {
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
		}
		
		
		this.addFriend = function(friend) {
			this.friends.push(friend);
		}
		
		this.addBest = function(bFriend) {
			var friend  	= this.friendByName(bFriend);
				friend.best = true;
			this.best_friends.push(friend);
		}
		
		
		var jsonFriends = updates["updates_response"].friends,
				 friend;
			
		for(var i in jsonFriends) {
			friend = new Snappy.Friend(jsonFriends[i]);
			this.addFriend(friend);
		}
		
		this.attachStories(updates["stories_response"]);
		
		return this;
	}
	

	this.Story = function(raw, loadEvent, userInfo) {
		if(!raw.story)
			return false;
	
		var story 	= raw.story,
			iv 		= story.media_iv,
			key		= story.media_key,
			id		= story.media_id;
		
		this.state 	= "decrypt";
		this.id 	= story.media_id;
		this.date	= new Snappy.SnappyDate(story.timestamp);
		
		this.changeBlocks = [];
		
		this.change = function(fn) {
			if(!fn) {
				for(var i in this.changeBlocks)
					this.changeBlocks[i](this);
				this.changeBlocks = [];
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
		this.conversations = [];
		
		for(var i in updates["conversations_response"])
			this.conversations.push(
				new Snappy.Conversation(updates["conversations_response"][i])
			);
	}
	this.Conversation = function(conversation) {
		this.snaps = [];
		this.users = [];
		for(var i = 1; i < conversation.participants.length; i++)
			this.users[i-1] = conversation.participants[i];
		
		var messages = conversation["conversation_messages"]["messages"];
		
		for(var i in messages) {
			var snap = messages[i].snap;
			if(snap)
				this.snaps.push(new Snappy.Snap(snap));
			else
				console.log("no snap", conversation);
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
		this.timer		= raw.t || null;
		
		this.changeBlocks = [];
		
		this.showInFinder = function() {
			SnapJS.showInFinder(this.urls.filePath);
		}
		this.change = function(fn) {
			if(!fn) {
				for(var i in this.changeBlocks) {
					if(typeof this.changeBlocks[i] == "function") {
						this.changeBlocks[i](this);
					}
				}
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
				_this.snap.change();
			});
		}
		
		this.load();
		
		return this;
	}
	
	this.SnappyDate = function(ts) {
		
		this.date = new Date(ts);
			
		this.timeSince = function() {
			
			var seconds  = Math.floor((new Date() - this.date) / 1000),
				interval = Math.floor(seconds / 31536000);
			
			if(interval > 1)
		        return interval + " années";
		        
		    interval = Math.floor(seconds / 2592000);
		    if(interval > 1)
		        return interval + " mois";
		        
		    interval = Math.floor(seconds / 86400);
		    if(interval > 1)
		        return interval + " jours";
		        
		    interval = Math.floor(seconds / 3600);
		    if(interval > 1)
		        return interval + " heures";
		        
		    interval = Math.floor(seconds / 60);
		    if(interval > 1)
		        return interval + " minutes";
		        
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
	
	return this; 
})();

function SnappyRClickHandler(element) {
	if(element.style)
		return Snappy.rightClick(element);
}
var SnapBack = function(var1, var2, var3) {
	if(typeof var1 == "function") {
		var id = (Math.round(Math.random()*10000000000)).toString();
			
		if(!var2)
			var2 = new Object();
		
		Snappy.tmp.SnapBack[id] = new SnapBack(var2, var1, id);
		
		return id;
	}
	else {
		for(var k in var1) {
			this[k] = var1[k];
		}
		
		this.id = var3;
		this.func = var2;
		this.call = function() {
			var vars = "";
			for(var i in arguments) {
				vars += "arguments["+i+"]"+(i == arguments.length-1 ? "": ", ");
			}
			try {
				eval("this.func.call(this"+(vars ? ", "+vars : "")+");");
			}
			catch(e) {
				console.error("There is an error with the Snappy runtime!", e);
				console.log("Var dump :", varsString, this);
			}
			this.destroy();
		}
		this.destroy = function() {
			delete Snappy.tmp.SnapBack[this.id];
		}
		
		return this;
	}
	
}
function SnapCall(id) {
	return Snappy.tmp.SnapBack[id];
	
}

