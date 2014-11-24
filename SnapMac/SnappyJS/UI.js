/*

###############################################################################################
#																							  #
#							   UI.js, part of Snappy Project								  #
#																							  #
#					#################################################						  #
#																							  #
#								  2014 - Fathy Boundjadj									  #
#																							  #
###############################################################################################


*/

function e(tag, cls, text, css) {
	var el = $("<"+tag+">", (typeof cls == "object" ? cls : null));
	
	if(typeof cls == "string")
		cls ? el.addClass(cls) : 1;
	
	text ? el.text(text) : 1;
	css ? el.css(css) : 1;
	
	return el;
}

function toggleClass(el, cls, bool) {
	el[(arguments.length == 3 ? bool : !el.hasClass(cls)) ? "addClass" : "removeClass"](cls);
}
SnappyUI = new (function() {
	
	this.use3D = function(value) {
		toggleClass(this.body, "enable3d", value);
	}
	
	this.hideSend = function() {
		if(!this.SendPage.isVisible())
			return;
			
		this.SendPage.hide();
		this.FeedPage.show();
	}
	this.logout = function() {
		this.LoginPage.show();
		this.FeedPage.erase();
		this.FriendsPage.erase();
		this.logged = false;
		this.updateKeychain();
	}
	
	$(document).ready(function() {
		SnappyUI.init();
	});
	
	return this;
})();

SnappyUI.init = function() {
	
	this.logged = false;
	this.body = $("body");
	this.updates = new Object();
	
	this.Header = function(parent) {
		this.element = e("header").appendTo(parent.element);
		
		this.leftButton = new (function(parent) {
			this.element = e("span", "leftButton")
							.appendTo(parent.element)
							.data("button", this);
			
			this.icon = "hide";
			
			this.setIcon = function(icon) {
				
				this.element.removeClass("spin");
				
				this.icon = icon;
				
				if(!icon)
					this.element.html("");
				else
					this.element.html(({
						back   : "4",
						update : "",
						loading: ""
					})[this.icon]);
				
				if(icon == "update" || icon == "loading")
					this.spin();
				
				this.element.css("font-size", icon == "back" ? "30px" : "20px");
			}
			this.spin = function(bool) {
				if(arguments.length == 1)
					this.spinVal = bool;
				
				this.element[this.spinVal ? "addClass" : "removeClass"]("spin");
			}
			this.element.click(function() {
				var button = $(this).data("button"),
					icon   = button.icon;
				
				switch(icon) {
					case "update":
						button.spin(true);
						SnappyUI.update();
						
						break;
					case "back":
						SnappyUI.FriendsPage.StoriesView.close();
						
						break;
				}
			});
				
		})(this);
		
		this.title = new (function(parent) {
			this.element = e("p").appendTo(parent.element);
			
			this.setTitle = function(title) {
				this.element.text(title);
			}
		})(this);
	}
	this.Section = function(_this, name) {
		_this.element = e("section", name).appendTo("body");
		
		_this.header = new SnappyUI.Header(_this);
		
		
		_this.hide = function() {
			this.element.removeClass("active");
		}
	
		_this.show = function() {
			if((!SnappyUI.logged && this.onlyShowIfLogged) || $(".zoom").length)
				return;
			
			if(SnappyUI.currentPage)
				SnappyUI.currentPage.hide();

			SnappyUI.currentPage = this;
			this.element.addClass("active");
			this.element.scrollTop(0);
			
			if(this.content)
				this.content.scrollTop(0);
		}
		
		_this.isVisible = function() {
			return this.element.hasClass("active");
		}
		
	}
	
	this.toggleCam = new (function() {
		this.element = e("span", "toggleCam");
		this.element.appendTo("body");
		this.icon = "hide";
		
		this.setIcon = function(icon) {
			this.icon = icon;
			this.element.html(this.icon == "hide" ? "^" : "5");
		}
		
		this.element.click(function() {
			if(SnappyUI.toggleCam.icon == "show")
				SnapJS.showCamera();
			else
				SnapJS.hideCamera();
		});
		
		this.setIcon("hide");
		
		return this;
	})();
	
	this.LoginPage = new (function() {
		
		SnappyUI.Section(this, "loginPage");
		
		this.header.title.setTitle("Connection");
		
		this.loginForm = e("form", "loginForm").appendTo(this.element);
		this.loginForm.submit(function() {
			return false;
		});
		
		this.inputLogin = e("input", {placeholder: "Login",
									  		 type: "text"}).appendTo(this.loginForm);
									  		 
		this.inputPassword = e("input", {placeholder: "Mot de passe",
												type: "password"}).appendTo(this.loginForm);
												
		this.connectBtn = e("button", 0, "Connection").appendTo(this.loginForm);
		
		this.connectBtn.click(function() {
			var username = SnappyUI.LoginPage.inputLogin.val(),
				password = SnappyUI.LoginPage.inputPassword.val(),
				leftButton = SnappyUI.LoginPage.header.leftButton;
			
			leftButton.setIcon("loading");
			leftButton.spin(true);
				
			Snappy.login(username, password, function(r) {
				console.log("login", r);
				
				
				if(r.error) {
					console.error(r.error);
					SnappyUI.logged = false;
					leftButton.spin(false);
					leftButton.setIcon(null);
				}
				else {
					SnappyUI.setUpdates(r);
					leftButton.spin(false);
					leftButton.setIcon(null);
				}
			});
		});
		
		
		this.iOSSync = new (function() {
			
			this.element = e("div", "iOSSync");
			
			
			this.header = new SnappyUI.Header(this);
			this.header.title.setTitle("Synchronisation iOS");
		
			this.accountList = e("select").data("syncClass", this).appendTo(this.element)
			this.accountList.change(function() {
				$(this).data("syncClass").selectedBackup = $(this).children("option:selected").data("bid");
			});
			
			this.button = e("button", 0, "Connection").appendTo(this.element);
			
			
			return this;
			
		})();
		
		this.iOSSync.element.appendTo(this.element);
		
		this.androSync = new (function() {
			
			this.element = e("div", "androSync");
			
			this.header = new SnappyUI.Header(this);
			this.header.title.setTitle("Synchronisation Android");
			
			e("p", 0, "Veuillez connecter un appareil Android rooté avec le débogage activé").appendTo(this.element);
			
			this.error = e("p", "androidError");
			this.error.appendTo(this.element);
			
			this.button = e("button", 0, "Connection");
			this.button.appendTo(this.element);
			this.button.click(function() {/*NEEEEEEEEEEEEEEEEEEEEED IMPLENTATION!!!!!!!!!!!!!!*/
				SnappyUI.LoginPage.androdSync.error.text("");
				$('body').addClass('loading');
				setTimeout(function() {
					if(!$('body').hasClass('loading')) return;
					$('body').removeClass('loading');
				}, 5000);
				SMClient.requestAndroidSync();
			});
			
			return this;
			
		})();
		
		this.androSync.element.appendTo(this.element);
		
		
		return this;
	})();
	
	this.FeedPage = new (function() {
		
		this.onlyShowIfLogged = true;
		
		SnappyUI.Section(this, "feedPage");
		
		this.header.title.setTitle("Mon fil");
		this.header.leftButton.setIcon("update");
		
		this.content = e("div", "content").appendTo(this.element);
		
		this.erase = function() {
			this.snapList = new Object();
			this.element.children(".snap").remove();
		}
		
		this.snapList = new Object();
		
		this.setConversations = function(conversations) {
			
		}
		this.conversationElement = function(conv) {
			var el = e("div", "conversation");
			
			
		}
		
		this.setSnapList = function(snapList) {
			return;
			for(var i in snapList.snaps) {
				var snap = snapList.snaps[i];
				
				if(!this.snapList[snap.id])
					this.snapList[snap.id] = snap;
			}
			this.update();
		}
		
		this.snapElement = function(snap) {
			var el 	 	  = e("div", "snap"),
				friend    = SnappyUI.updates.Friends.friendByName(snap.user),
				userText  = e("p", 0, (friend ? friend.displayName : snap.user)),
				iconDiv	  = e("p"),
				mediaType = snap.mediaType;
			
			
			function icon(icon) {
				return e("span", "icon", icon);
			}
			
			if(mediaType.isFriendRequest)
				iconDiv.append(icon(""));
			else
				iconDiv.append(icon(snap.received ? "8" : "9"));
			
			if(mediaType.isImage)
				iconDiv.append(icon(""));
			if(mediaType.isVideo)
				iconDiv.append(icon(""));
			if(mediaType.isAudio)
				iconDiv.append(icon("z"));
			
			userText.appendTo(el);
			iconDiv.appendTo(el);
			
			e("p", 0, "Il y a "+snap.date.timeSince()).appendTo(el);
			
			if(snap.mediaType.isFriendRequest)
				e("p", "acceptFriend", "Accepter").appendTo(el);
			
			el.attr("data-media-type", snap.mediaType.id);
			
			if(snap.url)
				el.css("background-image", "url('"+snap.url+"')");
			
			el.data("snap", snap)
			  .click(function() {
				  	var snap = $(this).data("snap");
				  	if(snap)
				  		SnapJS.showMedia(snap.id); 
			  });
		
			return el;
		}
		
		this.update = function() {
			for(var k in this.snapList) {
				var snap = this.snapList[k];
				
				if(snap.element)
					continue;
				
				snap.element = this.snapElement(snap);
				snap.element.appendTo(this.content);
				
				snap.change(function(snap) {
					if(!snap.url)
						snap.element.addClass("hide");
					else
						snap.element.css("background-image", "url('"+snap.url+"')");
				});
			}
		}
		
		return this;
	})();
	
	this.FriendsPage = new (function() {
		
		this.onlyShowIfLogged = true;
		
		SnappyUI.Section(this, "friendsPage");
		
		this.header.leftButton.setIcon("update");
		this.header.title.setTitle("Amis");
		
		this.content = e("div", "content").appendTo(this.element);
		
		this.zoom = function(bool) {
			this.content[bool ? "addClass" : "removeClass"]("zoom");
		}
		this.StoriesView = new (function(parent) {
			
			this.parent  = parent;
			this.element = e("div", "storiesToolbox")
							.appendTo(parent.content);
			
			this.erase = function() {
				this.element.children(".storyBox").remove();
				this.stories = new Array();
			}
			
			this.close = function() {
				this.erase();
			
				this.parent.content.scrollTop(SnappyUI.FriendsPage.content.data("scrollTop"));
				this.parent.zoom(false);
				
				this.parent.header.leftButton.setIcon("update");
				this.parent.header.title.setTitle("Amis");
			}
			this.setStories = function(stories) {
			
				this.parent.header.leftButton.setIcon("back");
				
				this.element.scrollTop(0);
				
				var story,
					storyBox,
					storyMage,
					dateText,
					friendsPage;
				
				for(var k in stories) {
					story = stories[k];
					
					storyBox = e("div", "storyBox")
							   .data("story", story)
							   .click(function() {
								   	var story = $(this).data("story");
								   	if(story)
								   		SnapJS.showMedia(story.id);
							   });
					
					storyMage = e("div", "imgStory")
								.appendTo(storyBox);
								
					dateText = e("p", 0, "Il y a "+story.date.timeSince())
							   .appendTo(storyBox);
					
					storyBox.data("img", storyMage)
							.appendTo(this.element)
							.addClass("loading");
					
					story.box = storyBox;
					var fn = function(story) {
						story.box.removeClass("loading")
								 .data("img")
								 .css('background-image', story.image == "" ? "" : "url('"+story.image+"')");
					}
					
					if(story.state != "loaded") {
						story.change(fn);
						story.load();
					}
					else
						fn(story);
					
					this.parent.header.title.setTitle("Histoires de "+story.friend.displayName);
					
					friendsPage = SnappyUI.FriendsPage;
					friendsPage.content.data('scrollTop', friendsPage.content.scrollTop());
					friendsPage.content.scrollTop(0);
					friendsPage.zoom(true);
				}
			}
			
			return this;
		})(this);
		
		this.erase = function() {
			this.friendList = new Object();
			this.element.children(".friend").remove();
		}
		this.friendList = new Object();
		
		this.setFriends = function(friendList) {
			var friend;
			
			for(var k in friendList.friends) {
				friend = friendList.friends[k];
				
				if(!this.friendList[friend.name])
					this.friendList[friend.name] = friend;
			}

			this.update();
		}
		
		
		this.friendElement = function(friend) {
			var el 	 	   = e("div", "friend"),
				storiesBtn = e("p", "storiesBtn", "Voir ses histoires "),
				numStories = e("span", "numStories").appendTo(storiesBtn),
				displayDiv = e("div", "displayName").appendTo(el);
			
			el.data({
					friend: friend,
				numStories: numStories
			});
			
			e("input", 0).attr({type:"text", "placeholder": "Nom"})
						 .val(friend.displayName)
						 .appendTo(displayDiv)
						 .keypress(function(event){
							 if(event.keyCode == '13')
							 	toggleClass($(this).parent(), "edit");
						 });;
						 
			e("p", 0, friend.displayName).appendTo(displayDiv)
										 .click(function(e) {
				toggleClass($(this).parent(), "edit"); 
			});
			
			e("p", "friendName", friend.name).appendTo(el);
			storiesBtn.appendTo(el);
			
			
			storiesBtn.click(function() {
				var friend  = $(this).parent().data("friend"),
					stories = friend.stories;
					
				if(!stories) {
					$(this).shake(3, 20, 500, true);
					return;
				}
				
				SnappyUI.FriendsPage.StoriesView.setStories(stories);				
			});

			return el;
		}
		this.update = function() {
			for(var name in this.friendList) {
				var friend = this.friendList[name];
				
				if(friend.element)
					continue;
				
				friend.change(function(friend) {
					friend.numStories = friend.element.data("numStories");
					friend.numStories.text(friend.stories.length ? "("+friend.stories.length+")" : "");
				});
				
				friend.element = this.friendElement(friend);
				friend.element.appendTo(this.content);
				
				friend.change();
				
			}
		}
		
		return this;
	})();
	
	this.SendPage = new (function() {
		
		this.onlyShowIfLogged = true;
		
		SnappyUI.Section(this, "sendPage");
		
		this.header.element.hide();
		
		this.searchInput = e("input");
		this.searchInput.appendTo(this.element)
						.attr({
							placeholder: "Rechercher...",
							results: "results",
							type: "search"
						})
						.on('input', function() {/////IMPLMETATIOOOOOOON
							var searchVal = $.trim($(this).val()).toLowerCase();
							
							SnappyUI.SendPage.friendList.hide();
							
							$.each(window.SMFriends, function() {
								if(~(this.name.toLowerCase().indexOf(searchVal)) || ~(friendDisplayName(this.name).toLowerCase().indexOf(searchVal)))
									$(".sendFriend[data-username='"+this.name+"']").parent().show();
							});
						});
		
		this.friendList = e("div", "friendList");
		this.friendList.appendTo(this.element);
		
		this.SendActions = new (function() {
			
			this.element = e("div", "sendPageActions");
		
			this.cancelBtn =  e("button", "cancel", "Annuler").appendTo(this.element);
			this.selectBtn =  e("button", "select").appendTo(this.element);
			this.sendBtn   =  e("button", "send", "Envoyer (").appendTo(this.element);
			this.shareBtn  =  e("button", "share", "Partager").appendTo(this.element);
			this.saveBtn   =  e("button", "save", "Enregistrer").appendTo(this.element);
			
			this.checkBtn = e("div", "check").appendTo(this.selectBtn);
			
			this.selectedCount = e("span", "selectedFriendNum", "0");
			this.sendBtn.append(this.selectedCount)
						.append(")");
			
			this.cancelBtn.click(function() {
				SnappyUI.FeedPage.show();
				SnapJS.camView().cleanStart();
			});
			this.sendBtn.click(function() {
				SMClient.sendPhoto();
			});
			this.selectBtn.click(function() {
				
				var checkBtn = SnappyUI.SendPage.SendActions.checkBtn;
				if(checkBtn.hasClass('checked')) {
					$('.friendList>div .check:visible').removeClass('clicked');
					checkBtn.removeClass('checked');
				}
				else {
					$('.friendList>div .check:visible').addClass('clicked');
					checkBtn.addClass('checked');
				}
				var nbrAmis = $(".friendList .clicked").length;
				$('.selectedFriendNum').text(nbrAmis);
			});
			
			return this;
		});
		
		this.SendActions.element.appendTo(this.element);
		
		return this;
	})();
	
	this.setUpdates = function(updates) {
		
		this.logged = true;
		this.updates = updates;
		
		this.FeedPage.setConversations(updates.Conversations);
		
		if(this.LoginPage.isVisible() || !SnappyUI.currentPage) {
			this.logged = true;
			this.FeedPage.show();
		}
		
		this.FriendsPage.setFriends(updates.Friends);
	}
	
	this.use3D(SnapJS.use3D());
	
	this.update = function() {
		Snappy.getUpdates(function(updates) {
			if(updates.error)
				console.log(updates.error);
			else {
				SnappyUI.FeedPage.header.leftButton.spin(false);
				SnappyUI.FriendsPage.header.leftButton.spin(false);
				SnappyUI.setUpdates(updates);
			}
		
		});
	}
	
	Snappy.rightClick = function(element) {
		var el	  = $(element),
			items = new Object();
		
		if(el.is(".snap")) {
			var snap = $(el).data("snap");
			items["Voir le fichier"] = function() {
				snap.showInFinder();
			}
			items["separator"] = null;
		}
		if(el.is(".friend")) {
			var friend = el.data("friend");
			
			items["Renommer"] = function() {
				el.children(".displayName").addClass("edit");
			}
			/*
			items["Supprimer "+friend.displayName] = function() {
				
			}
			items["Bloquer "+friend.displayName] = function() {
				
			}*/
		}
		
		return items;
	}
	
	this.updateKeychain = function() {
		Snappy.getKeychain(function(account) {
			if(!account)
				return;
			
			if(account.login)
				SnappyUI.LoginPage.inputLogin.val(account.login);
			if(account.pass)
				SnappyUI.LoginPage.inputPassword.val(account.pass);
		});
	}
	
	Snappy.getUpdates(function(updates) {
		console.log("updates", updates);
		if(updates.error) {
			SnappyUI.updateKeychain();
			SnappyUI.LoginPage.show();
		}
		else
			SnappyUI.setUpdates(updates);
	});
}
