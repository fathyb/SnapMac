function e(tag, cls, text, css) {
	var el = $("<"+tag+">", (typeof cls == "object" ? cls : null));
	
	if(typeof cls == "string")
		cls ? el.addClass(cls) : 1;
	
	text ? el.text(text) : 1;
	css ? el.css(css) : 1;
	
	return el;
}

function toggleClass(el, cls) {
	el[el.hasClass(cls) ? "removeClass" : "addClass"](cls);
}
SnappyUI = new (function() {
	
	this.use3D = function(value) {
		toggleClass(this.body, "enable3d");
	}
	
	this.setLoading = function(bool) {
		this.body[bool ? "addClass" : "removeClass"]("loading");
	}
	
	this.hideSend = function() {
		if(!this.SendPage.isVisible())
			return;
			
		this.SendPage.hide();
		this.SnapsPage.show();
	}
	
	return this;
})();

SnappyUI.init = function() {
	
	this.logged = false;
	this.body = $("body");
	this.updates = new Object();
	
	this.Header = function(_this) {
		this.element = e("header").appendTo(_this.element);
		
		
		this.title = new (function() {
			this.element = e("p");
			
			this.setTitle = function(title) {
				this.element.text(title);
			}
		})();
		this.title.element.appendTo(this.element);
	}
	this.Section = function(_this, name) {
		_this.element = e("section", name).appendTo("body");
		
		_this.header = new SnappyUI.Header(_this);
		
		_this.hide = function() {
			this.element.removeClass("active");
		}
	
		_this.show = function() {
			if(!SnappyUI.logged && this.onlyShowIfLogged)
				return;
			$(".active").removeClass("active");
			this.element.addClass("active");
			this.element.scroll(0);
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
			if(SnappyUI.toggleCam.icon == "show") {
				SnappyUI.toggleCam.setIcon("hide");
				SnapJS.showCamera();
			}
			else {
				SnappyUI.toggleCam.setIcon("show");
				SnapJS.hideCamera();
			}
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
			SnappyUI.setLoading(true);
			
			var username = SnappyUI.LoginPage.inputLogin.val(),
				password = SnappyUI.LoginPage.inputPassword.val();
			
			Snappy.login(username, password, function(r) {
				SnappyUI.setLoading(false);
				if(r.error) {
					SnappyUI.logged = false;
					console.log("Error lors de la connection", r.error);
					//ERRRRROR
				}
				else {
					SnappyUI.setUpdates(r);
				}
			});
		});
		
		
		this.iOSSync = new (function() {
			
			this.element = e("div", "iOSSync");
			
			e("h1", 0, "Compte iOS").appendTo(this.element);
		
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
			
			e("h1", 0, "Compte Android").appendTo(this.element);
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
	
	this.SnapsPage = new (function() {
		
		this.onlyShowIfLogged = true;
		
		SnappyUI.Section(this, "snapsPage");
		
		this.header.title.setTitle("Mon fil");
		
		e("p", "name").appendTo(this.element);
		
		this.snapList = new Object();
		this.setSnapList = function(snapList) {
			for(var i in snapList.snaps) {
				var snap = snapList.snaps[i];
				
				if(!this.snapList[snap.id])
					this.snapList[snap.id] = snap;
			}
			this.update();
		}
		
		this.snapElement = function(snap) {
			var el 	 	= e("div", "snap"),
				friend  = SnappyUI.updates.FriendList.friendByName(snap.user),
				name 	= friend ? friend.displayName : snap.user;
			
			if(snap.mediaType.isFriendRequest)
				e("p", 0, "Demande d'amitié").appendTo(el);
			
			e("p", 0, (snap.received ? "De" : "À") + " "+name).appendTo(el);
			e("p", 0, "Il y a "+timeSince(snap.date)).appendTo(el);
			
			if(snap.mediaType.isFriendRequest)
				e("p", "acceptFriend", "Accepter").appendTo(el);
			
			el.attr("data-media-type", snap.mediaType.id);
			
			if(snap.url)
				el.css("background-image", "url('"+snap.url+"')");
			
			return el;
		}
		
		this.update = function() {
			for(var k in this.snapList) {
				var snap = this.snapList[k];
				
				if(snap.element)
					continue;
				
				snap.element = this.snapElement(snap);
				snap.element.appendTo(this.element);
				
				snap.change(function(snap) {
					if(!snap.url)
						snap.element.addClass("hide");
					else
						snap.element.css("background-image", "url('"+snap.url+"')");
						
						
					console.log("snap change", snap);
				});
			}
		}
		
		return this;
	})();
	
	this.FriendsPage = new (function() {
		
		this.onlyShowIfLogged = true;
		
		SnappyUI.Section(this, "friendsPage");
		
		this.header.title.setTitle("Amis");
		
		this.StoriesView = new (function() {
			this.element = e("div", "storiesToolbox");
			
			this.backBtn = e("span", "storyBack", "Retour").appendTo(this.element);
			this.user	 = e("span", "user");
			
			e("p", 0, "Histoire de ").append(this.user).appendTo(this.element);
			
			return this;
		})();
		
		this.StoriesView.element.appendTo(this.element);
		
		this.friendList = new Object();
		
		this.setFriendList = function(friendList) {
			this.friendList = friendList;
			this.update();
		}
		
		
		this.friendElement = function(friend) {
			var el 	 	   = e("div", "friend"),
				storiesBtn = e("p", "storiesBtn", "Voir son histoire "),
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
							 if(event.keyCode == '13') {
							 	toggleClass($(this).parent(), "edit"); 
							 }
						 });;
						 
			e("p", 0, friend.displayName).appendTo(displayDiv)
										 .click(function(e) {
				toggleClass($(this).parent(), "edit"); 
			});
			
			e("p", "friendName", friend.name).appendTo(el);
			storiesBtn.appendTo(el);
			
			
			storiesBtn.click(function() {
				/*var user = $(this).parent().data('friend').name;
				var story = getUserStory(user).stories;
				if(!story) {
					$(this).shake(3, 20, 500, true);
					return;
				}
				$('.storyBox').remove();
				$.each(story, function() {
					var story = this.story;
					var id = story.media_id;
					var iv = story.media_iv;
					var key = story.media_key;
					if(!$(".storyBox[data-id='"+id+"']").length) $('.storiesToolbox').append("<div class='storyBox' data-id='"+id+"'><div class='imgStory'></div><p>Il y a "+timeSince(story.timestamp)+"</p></div>");
					SMClient.getStory(id, key, iv, SMCallback(function(id, result) {
						$(".storyBox[data-id='"+id+"']").click(function() {
							var id = $(this).data("id")+"";
							SMClient.showSnap(id);
						}).children(".imgStory").css('background-image', "url('"+result+"')");
					}));
				});
				$('.storiesToolbox .user').text(friendDisplayName(user));
				var friends = $('.friendsPage').addClass('zoom')
				var scroll = $('.friendsPage').scrollTop();
				friends.scrollTop(0);
				friends.attr('data-oldScroll', scroll);*/
				
				
			});

			
			
			
			
			
			
			return el;
		}
		this.update = function() {
			for(var k in this.friendList.friends) {
				var friend = this.friendList.friends[k];
				
				if(friend.element)
					continue;
				
				friend.element = this.friendElement(friend);
				friend.element.appendTo(this.element);
				
				friend.numStories = friend.element.data("numStories");
				friend.numStories.text(friend.stories.length ? "("+friend.stories.length+")" : "");
			}
		}
		
		return this;
	})();
	
	this.SendPage = new (function() {
		
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
				SMClient.cancelSend();
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
	
	this.hideAll = function() {
		var pages = "Login:Snaps:Send:Friends".split(":");
		for(var k in pages)
			this[pages[k]+"Page"].hide();
	}

	this.setUpdates = function(updates) {
		
		this.logged = true;
		this.updates = updates;
		
		this.SnapsPage.setSnapList(updates.SnapList);
		this.SnapsPage.show();
		
		this.FriendsPage.setFriendList(updates.FriendList);
	}
	
	this.use3D(SnapJS.use3D());
	
	SnappyUI.LoginPage.show();
	Snappy.getUpdates(function(updates) {
		if(updates.error)
			SnappyUI.LoginPage.show();
		else
			SnappyUI.setUpdates(updates);
		
	});
	
	
		var account = JSON.parse(SMClient.account());
		if(!account.error) {
			$('.loginForm input[type=text]').val(account.login);
			$('.loginForm input[type=password]').val(account.pass);
		}
	
	this.toggleCam.element.click();
}
