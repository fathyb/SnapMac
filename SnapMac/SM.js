


jQuery.fn.shake = function(intShakes, intDistance, intDuration, margin) {
	var prop = (margin ? "margin-left" : "left");
	this.each(function() {
		$(this).css("position", "relative");
		for (var x=1; x<=intShakes; x++) {
			$(this).animate({prop:(intDistance*-1)}, (((intDuration/intShakes)/4)))
			.animate({prop:intDistance}, ((intDuration/intShakes)/2))
			.animate({prop:0}, (((intDuration/intShakes)/4)));
		}
	});
	return this;
}

String.prototype.endsWith = function(suffix) {
    return this.indexOf(suffix, this.length - suffix.length) !== -1;
}
function updateOnlineStatus(e) {
	navigator.onLine ? $('body').removeClass('offline') : $('body').addClass('offline');
}

window.addEventListener('online',  updateOnlineStatus);
window.addEventListener('offline', updateOnlineStatus);


$(document).ready(function() {
//$("section").unbind("mousemove").mousemove(function(e) { var x = e.clientX, y = e.clientY, w = window.innerWidth, h = window.innerHeight;  $("section").css("-webkit-perspective-origin", ((w-x)/2)+"px "+((h-y)/2)+"px");});
	/*$('section').scroll(function() {
		$(this).css("-webkit-perspective-origin-y", ((this.scrollTop+window.innerHeight)/this.scrollHeight*100)+"%");
	});*/
	
	SnappyUI.init();
	
	/*$('.iOSAccountConnection').click(function() {
		$('body').addClass('loading');
		setTimeout(function() {
			var selected = $('.iOSAccountsList option:selected');
			var token = selected.attr("token"), login = selected.attr("login");
			var connected = !(!tryConnection(token, login) || !token || !login);
			$('body').removeClass('loading');
			if(!connected)
				$('.iOSAccountsList').shake(3, 20, 500);
		}, 50);
	});
	$('.storyBack').click(function() {
		showPage('friends');
	})
	refreshiOSAccounts();
	updateOnlineStatus(false);
	$('body').addClass('loading');
	var authToken = SMClient.defaultAuthToken(), login = SMClient.defaultLogin();
	setTimeout(function() {
		if(tryConnection(authToken, login)) return;
		$('body').removeClass('loading');
		var account = JSON.parse(SMClient.account());
		if(!account.error) {
			$('.loginForm input[type=text]').val(account.login);
			$('.loginForm input[type=password]').val(account.pass);
		}
	}, 100);*/
	
});
function getFriendsList() {
	var friends = "";
	var i = 0;
	$('.friendList>div .check.clicked').each(function() {
		var friend = $(this).parent().children(".sendFriend").data("username");
		friends += (!i ? "" : ",")+friend;
		i++;
	});
	return friends;
}
function getUserStory(user) {
	var story = false;
	$.each(window.SMStories.friend_stories, function() {
		if(this.username == user) story = this;
	});
	return story;
}
function updateStories(stories) {
	var fStories = stories.friend_stories;
	window.SMStories = stories;
	$('.storiesBtn').unbind('click').click(function() {
		var user = $(this).parent().data('username');
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
		friends.attr('data-oldScroll', scroll);
	});
	$.each(fStories, function(i) {
		var friendDiv = $(".friend[data-username='"+this.username+"'] .storiesBtn");
		if(friendDiv.length) friendDiv.children('.numStories').text("("+this.stories.length+")");
	});
}


function updateFriends() {
	var friends = window.SMFriends;
	if(!friends) return;
	var uglyChecker = {};
	$.each(friends, function() {
		var friend = $(".friendsPage .friend[data-username='"+this.name+"']");
		if(!friend.length)
			friend = $("<div>").appendTo(".friendsPage");
		else
			friend.children("*").remove();
		friend.addClass("friend");
		friend.attr("data-username", this.name);
		friend.append("<p>"+friendDisplayName(this.name)+"</p>");
		friend.append("<p class='friendName'>"+this.name+"</p>");
		friend.append("<p class='sendSnapBtn'>Envoyer un snap</p>");
		friend.append("<p class='storiesBtn'>Voir son histoire <span class='numStories'></span></p>");
		uglyChecker[this.name] = true;
	});
	$(".friendsPage .friend").each(function() {
		if(!($(this).data("username") in uglyChecker))
			$(this).remove();
	});
	SMClient.getStoriesWithCallback("updateStories");
}
//
function addThumbForSnap(thumb, snap) {
	var snap = $('div.snap[data-id="'+snap+'"]');
	snap.css("background-image", "url(play.png), url('"+thumb+"')");
}
function getSnap(id, t) {
		var saved = hasSnapSaved(id);
		if(t && !saved) {
			//SMClient.getSnap(id);
			SMClient.getSnapWithCallback(id, "getSnap");
			saved = hasSnapSaved(id);
		}
		var snap = $('div.snap[data-id="'+id+'"]');
		if(saved) {
			if(saved.endsWith("_thumb.png"))
				snap.css("background-image", "url(play.png), url('"+saved+"')");
			else
				snap.css("background-image", "url('"+saved+"')");
		}
		else {
			snap.addClass("hide");
		}
}
function SMUpdate(updates) {
	
	if(!updates) {
		return SMClient.reqUpdate();
	}
	try {
		if(typeof(updates) == "string") updates = JSON.parse(updates);	
	}
	catch(e) {
		window.isConnected = false;
		return false;
	}
	window.isConnected = true;
	window.SMFriends = updates["friends"];
	//if($('div.snap[data-id="'+updates["snaps"][0].id+'"]').length) return;
	$('div.snap').remove();
	$.each(updates["snaps"], function() {
		if($('div.snap[data-id="'+this.id+'"]').length) return getSnap(this.id, this.t);
		var type = (this.sn ? "r" : "s");
		var name = (type == "r" ? this.sn : this.rp);
		var date = new Date(this.ts);
		//console.log(hasSnapSaved(this.id), (hasSnapSaved(this.id) ? "" : "class=\"hide\""));
		var snap = $("<div>").addClass("snap");
		snap.attr("data-id", this.id);
		if(this.m == 3)
			snap.append("<p>Demande d'amis</p>");
		snap.append("<p>"+(type == "r" ? "De" : "À")+" "+friendDisplayName(name)+"</p>");
		snap.append("<p>Il y a "+timeSince(this.ts)+"</p>");
		if(this.m == 3)
			snap.append("<p class='acceptFriend'>Accepter</p>");
		snap.appendTo('.snapsPage');
		snap.attr("data-media-type", this.m);
		getSnap(this.id, this.t);
	});		
	$('div.snap').unbind("click").click(function() {
		var id = $(this).data("id")+"";
		SMClient.showSnap(id);
	});
	showPage("snaps");
	updateFriends();
	window.currentTimer = setInterval(doUpdate, 10000);
	return true;
}
function logout() {
	if(window.updateInterval) clearInterval(window.updateInterval);
	SMClient.useAuthToken("", "");
	$('div.snap').remove();
	$('.name').text("");
	showPage("login");
	window.isConnected = false;
}
function showSend() {
	showPage("send");
	$('.sendPage .friendList>div').remove();
	$('.selectedFriendNum').text('0');
	$('.sendPageActions .check').removeClass('checked');
	$.each(window.SMFriends, function(i) {
		var friend = $('<div>');
		$('<div>').addClass('check').click(function() {
			if($(this).hasClass('clicked')) $(this).removeClass('clicked');
			else $(this).addClass('clicked');
			
			var nbrAmis = $(".friendList .clicked").length;
			$('.selectedFriendNum').text(nbrAmis);
		}).appendTo(friend);
		friend.append("<div class='sendFriend' data-username='"+this.name+"'><p>"+friendDisplayName(this.name)+"</p><p>"+this.name+"</p></div>");
		friend.appendTo(".sendPage .friendList");
	});
}
function showPage(page) {
	if(!window.isConnected) return;
	$('.zoom').each(function() {
		$(this).scrollTop($(this).data("oldScroll"));
	});
	$('.zoom').removeClass('zoom');
	$('section.active').removeClass('active');
	$('.'+page+'Page').addClass('active');
}
function friendDisplayName(friend) {
	if(!window.SMFriends) return friend;
	var friendName = friend;
	$.each(window.SMFriends, function() {
		if(this.name == friend && $.trim(this.display) != "") friendName = this.display;
	});
	return friendName;
}
function tryConnection(token, login) {
	SMClient.useAuthToken(token, login);
	var updates = SMClient.getUpdates();
	if(updates) {
		window.token = token;
		window.login = login;
		$('p.name').text(login);
		SMUpdate(JSON.parse(updates));
		doLogin();
	}
	return !!updates;
}
function refreshiOSAccounts() {
	var accounts = getiOSAccounts();
	if(!Object.keys(accounts).length) return $('.iOSAccountsList').append("<option data-noBackup=\"true\">Aucune sauvegarde iOS</option>");
	$.each(accounts, function(device) {
		$("<option>").text(this[0]+" : "+device).attr({token:this[1], login:this[0]}).appendTo('.iOSAccountsList');
	});
}
function getiOSAccounts() {
	return JSON.parse(SMClient.listBackups());
}
function androidSync(obj) {
	$('body').removeClass('loading');
	if(obj.error) {
		$('.androidError').css('color', 'red').text(obj.error);
		return;
	}
	if(!tryConnection(obj.authToken, obj.login)) {
		$('.AndroidAccountConnection').shake(3, 20, 500);
	}
}
function SMCallback(fn) {
	var ts = new Date();
	window[ts] = fn;
	return ""+ts;
}
function hasSnapSaved(snap) {
	return SMClient.hasSnapSaved(snap);
}
function timeSince(date) {
    var seconds = Math.floor((new Date() - date) / 1000);
    var interval = Math.floor(seconds / 31536000);
    if (interval > 1) {
        return interval + " années";
    }
    interval = Math.floor(seconds / 2592000);
    if (interval > 1) {
        return interval + " mois";
    }
    interval = Math.floor(seconds / 86400);
    if (interval > 1) {
        return interval + " jours";
    }
    interval = Math.floor(seconds / 3600);
    if (interval > 1) {
        return interval + " heures";
    }
    interval = Math.floor(seconds / 60);
    if (interval > 1) {
        return interval + " minutes";
    }
    return Math.floor(seconds) + " secondes";
}
function doUpdate() {
	//SMUpdate();
}
