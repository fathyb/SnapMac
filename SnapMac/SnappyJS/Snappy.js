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
		this.SnapList 	= snaps;
		this.FriendList = friends;
		
		return this;
	}
	
	this.updateParser = function(result, callback) {
		if(!callback)
			var callback = this.callback;
			
		if(result.error) {
			callback(result);
			return;
		}
						
		var friendList	= new Snappy.FriendList(result);
			snapList	= new Snappy.SnapList(result),
			updates		= new Snappy.Updates(friendList, snapList);
							
							
		friendList.onload = function() {
			callback(updates);
		}
	}
	
	this._loginCallback = null;
	this.login = function(username, password, callback) {
		this._loginCallback = callback;
		SnapJS.login(username, password, SnapBack(function(r) {
			if(r.error) {
				Snappy._loginCallback(r);
			}
			else {
				Snappy.getUpdates(function(r) {
					Snappy._loginCallback(r);
				}, r.updates);
			}
		}));
	}
	this.getUpdates = function(callback, updates) {
		if(!updates)
			SnapJS.getUpdates(SnapBack(this.updateParser, {callback: callback}));
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
			if(!fn) {
				for(var i in this.changeBlocks)
					this.changeBlocks[i](this);
			}
			else if(typeof fn == "function") {
				this.changeBlocks.push(fn);
			}
			
		}
		
		this.addStories	 = function(stories) {
			for(var i in stories) {
				this.stories.push(new Snappy.Story(stories[i], function(obj) {
					console.log("story callback", obj);
				}));
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
			if(this.onload)
				this.onload();
		}
		
		
		this.addFriend = function(friend) {
			this.friends.push(friend);
		}
		
		this.addBest = function(bFriend) {
			var friend  	= this.friendByName(bFriend);
				friend.best = true;
			this.best_friends.push(friend);
		}
		
		
		var jsonFriends = updates["added_friends"],
				 friend;
			
		for(var i in jsonFriends) {
			friend = new Snappy.Friend(jsonFriends[i]);
			this.addFriend(friend);
		}
		
		
		SnapJS.getStories(SnapBack(function(stories) {
			this.friendList.attachStories(stories);
		}, {friendList: this}));
		
		return this;
	}
	

	this.Story = function(raw, loadEvent) {
		if(!raw.story)
			return false;
	
		var story 	= raw.story,
			iv 		= story.media_iv,
			key		= story.media_key,
			id		= story.media_id;
		
		this.state 	= "decrypt";
		this.id 	= story.media_id;
		this.date	= new Date(story.timestamp);
		
		
		SnapJS.getStory(id, key, iv, SnapBack(function(image) {
			if(typeof image == "string") {
				this.story.state = "loaded";
				this.story.image = image;
				this.loadEvent(this.story);
			}
			else {
				console.log(image); 
			}
		}, {story: this, loadEvent: loadEvent}));
		return this;
		
	}
	
	this.SnapList = function(raw) {
		this.snaps = [];
		
		this.listSnapsByName = function() {
			
		}
		
		
		var snap,
			rawSnaps = raw.snaps;
			
		for(snapid in rawSnaps) {
			snap = new Snappy.Snap(rawSnaps[snapid]);
			this.snaps.push(snap);
		}
		
		return this;
	}
	
	this.Snap = function(raw) {
		this.received 	= !!raw.sn;
		this.sent		=  !raw.sn;
		this.user		= this.received ? raw.sn 	: raw.rp;
		this.sender		= this.received ? this.user : "me";
		this.dest 		= this.sent 	? this.user : "me";
		
		this.id			= raw.id;
		this.date		= new Date(raw.ts);
		this.mediaType 	= new Snappy.MediaType(raw.m);
		this.state		= kStateLoading;
		this.url		= null;
		this.timer		= raw.t || null;
		
		this.changeBlocks = [];
		
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
			SnapJS.getSnap(this.id, SnapBack(function(result) {
				if(!result || result.error) {
					return console.error("Error snap");
				}
				
				if(result.url) {
					this.snap.url = result.url;
					this.snap.change();
				}
			}, {snap: this}));
		}
		
		this.load();
		
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
		
		for(var k in mask) {
			this["is"+k] = a(mask[k]);
		}
		
		return this;
	}
	
	this.tmp = {
		SnapBack: {}
	}
	
	return this; 
})();


var SnapBack = function(var1, var2) {
	if(typeof var1 == "function") {
		var id = (Math.round(Math.random()*10000000000)).toString();
			
		if(!var2)
			var2 = new Object();
		
		Snappy.tmp.SnapBack[id] = new SnapBack(var2, var1);
		
		return id;
	}
	else {
		for(var k in var1) {
			this[k] = var1[k];
		}
		
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

