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
	$(el)[(arguments.length == 3 ? bool : !$(el).hasClass(cls)) ? "addClass" : "removeClass"](cls);
}

function UI() {
	
	return this;
}

UI.prototype = new (function() {
	
	this.Header = function(parent) {
		this.element = e("header").appendTo(parent.element);
		this.parent  = parent;
		
		this.leftButton = new (function(parent) {
			this.element = e("span", "leftButton")
							.appendTo(parent.element)
							.data("button", this);
			
			this.hide = function() {
				this.element.hide();
			}
			this.show = function() {
				this.element.show();
			}
			
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
						SnappyUI.currentPage.close();
						
						break;
				}
			});
				
		})(this);
		
		this.rightButton = new (function(parent) {
			this.icon	 = "";
			this.parent  = parent;
			this.element = e("span", "rightButton")
							.appendTo(parent.element)
							.data("button", this);
			
			this.hide = function() {
				this.element.hide();
			}
			this.show = function() {
				this.element.show();
			}
			
			this.setIcon = function(icon) {
				
				this.element.removeClass("spin");
				
				this.icon = icon;
				
				if(!icon)
					this.element.html("");
				else
					this.element.html(({
						search : "U",
						clear  : "Q"
					})[this.icon]);
				
				
				this.element.css("font-size", "20px");
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
					case "search":
						if($(this).hasClass("active")) {
							$(this).removeClass("active");
							this.parent.parent.search.hide();
						}
						else {
							$(this).addClass("active");
							this.parent.parent.search.show();
						}
						break;
					case "clear":
						SnapJS.clearFeed();
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
			if(SnappyUI.currentPage != this)
				return;
				
			SnappyUI.currentPage = null;
			
			if(this.hidden)
				this.hidden();
				
			this.element.removeClass("active");
		}
	
		_this.show = function(force) {
			var currentPage = SnappyUI.currentPage;
			if(((!SnappyUI.logged && this.onlyShowIfLogged)
				|| $(".zoom").length
				|| currentPage == SnappyUI.SendPage) && !force)
				return;
				
			if(currentPage == this) {
				$(this.content).animate({scrollTop: 0}, 500);
				return;
			}
			
			if(this.showed)
				this.showed();
				
			if(currentPage)
				currentPage.hide();

			SnappyUI.currentPage = this;
			this.element.addClass("active");
			this.element.scrollTop(0);
			
			SnapJS.clearSearchField();
			if(this.search)
				this.search("");
			
			if(this.content)
				this.content.scrollTop(0);
		}
		
		_this.blur = function(bool) {
			toggleClass(this.element, "blur", bool);
		}
		_this.zoom = function(bool) {
			this.header.leftButton.setIcon("back");
			toggleClass(this.content, "zoom", bool);
		}
		_this.isVisible = function() {
			return this.element.hasClass("active");
		}
		
	}
	

	
	this.updateFrame = function() {
		if(!$("body").hasClass("enableParallax"))
			return;
			
		this.FriendsPage.StoriesView.updateFrame();
		webkitRequestAnimationFrame(this.updateFrame);
	}
	this.setUpdates = function(updates) {
		
		this.logged = true;
		this.updates = updates;
		
		this.FeedPage.setConversations(updates.Conversations);
		
		if(this.LoginPage.isVisible() || !this.currentPage) {
			this.logged = true;
			this.FeedPage.show();
		}
		
		this.FriendsPage.setFriends(updates.Friends);
		this.SendPage.setFriends(updates.Friends);
	}
	
	this.updated = false;
	this.update = function() {
		var _this = this;
		Snappy.getUpdates(function(updates) {
			_this.LoadingPage.hide();
			if(updates.error) {
				if(!_this.updated) {
					_this.updated = true;
					_this.updateKeychain();
				}
				_this.ErrorView.showError(updates.error);
			}
			else {
				_this.FeedPage.header.leftButton.spin(false);
				_this.FriendsPage.header.leftButton.spin(false);
				_this.setUpdates(updates);
			}
		
		});
	}
	
	this.contextMenuForElement = function(element) {
		var el	  = $(element),
			items = new Object();
		
		if(el.parents(".snap").length || el.is(".snap")) {
			if(!el.is(".snap"))
				el = el.parents(".snap");
				
			var snap = $(el).data("snap");
			items[loc("Show in Finder")] = function() {
				snap.showInFinder();
			}
			items["separator"] = null;
		}
		if(el.parents(".friend").length || el.is(".friend")) {
			if(!el.is(".friend"))
				el = el.parents(".friend");
				
			var friend = el.data("friend");
			
			items[friend.displayName] = "disabled";
			items["separator"] = null;
			items[loc("Rename")] = function() {
				el.children(".displayName").addClass("edit");
			}
			
			items[loc("Delete")] = function() {
				
			}
			items[loc("Block %@", friend.displayName)] = function() {
				
			}
		}
		
		return items;
	}
	
	var _this = this;
	
	Snappy.search = function(str) {
		console.log(str);
		_this.search(str);
	}
	
	this.search = function(str) {
		if(this.currentPage && this.currentPage.search)
			this.currentPage.search(str);
	}
	this.updateInterval = null;
	this.setUpdateInterval = function(time) {
		if(this.updateInterval)
			clearInterval(this.updateInterval);
		
		this.updateInterval = setInterval(function() {
			if(SnappyUI.logged)
				SnappyUI.update();
		}, time*1000);
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
	
	this.init = function() {
	
		this.FriendsPage = new FriendsPage();
		this.LoadingPage = new LoadingPage();
		this.LoginPage	 = new LoginPage();
		this.SendPage 	 = new SendPage(this);
		this.FeedPage	 = new FeedPage();
		this.ErrorView	 = new ErrorView(this);
		this.toggleCam   = new ToggleCamView();
		this.logged		 = false;
		this.body		 = $("body");
		this.updates	 = new Object();
		
		var _this = this;
		
		Snappy.rightClick = function(element) {
			return _this.contextMenuForElement(element);
		}
		Snappy.search = function(str) {
			_this.search(str);
		}
		
		
		this.setTheme(SnapJS.darkTheme() ? "dark" : "light");
		this.use3D(SnapJS.use3D());
		this.useParallax(SnapJS.useParallax());
		this.hideFeedPics(SnapJS.hideFeedPics());
		this.update();
	
		this.setUpdateInterval(60);
		this.LoginPage.show();
		this.LoadingPage.show();
	}
	
	
	this.use3D = function(value) {
		toggleClass(this.body, "enable3d", value);
	}
	this.setTheme = function(theme) {
		if(theme == "light")
			this.body.removeClass("dark").addClass("light");
		else
			this.body.removeClass("light").addClass("dark");
	}
	this.useParallax = function(value) {
		toggleClass(this.body, "enableParallax", value);
		this.updateFrame();
	}
	this.uhfp = function() {
		this.hideFeedPics(SnapJS.hideFeedPics());
	}
	this.hideFeedPics = function(value) {
		toggleClass(this.body, "hideFeedPics", value);
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
		this.updates = new Object();
		
		SnapJS.logout();
	}
	
	$(document).ready(function() {
		SnappyUI.init();
	});
	
	return this;
})();

var SnappyUI = new UI();


function ToggleCamView() {
	this.element = e("span", "toggleCam");
	this.element.appendTo("body");
	this.icon = "hide";
		
	this.setIcon = function(icon) {
		this.icon = icon;
		this.element.html(this.icon == "hide" ? "^" : "5");
	}
	var _this = this;
	this.element.click(function() {
		if(_this.icon == "show")
			SnapJS.showCamera();
		else
			SnapJS.hideCamera();
	});
		
	this.setIcon("hide");
		
	return this;
}