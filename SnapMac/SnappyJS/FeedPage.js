function FeedPage() {

    this.onlyShowIfLogged = true;

    SnappyUI.Section(this, "feedPage");

    this.header.title.setTitle(loc("My feed"));
    this.header.leftButton.setIcon("update");
    this.header.rightButton.setIcon("clear");

    this.content = e("div", "content").appendTo(this.element);
	
	this.search = function(str) {
		if(this.content.hasClass("zoom"))
			return;
			
		if(!str) {
			for(var i in this.conversations)
				this.conversations[i].element.show();
		}
		else {
			for(var i in this.conversations) {
				var conversation = this.conversations[i],
					user = null,
					j = 0;
					
				conversation.element.hide();
				
				for(j in conversation.users) {
					user = conversation.users[j];
					if(user.toLowerCase().indexOf(str.toLowerCase()) != -1)
						conversation.element.show();
				}
			}
		}	
	}
    this.erase = function() {
        this.conversations = new Object();
        this.content.children(".conversation").remove();
    }


    this.close = function() {
        this.ConversationsView.close();
        this.content.scrollTop(this.content.data("scrollTop"));
        this.zoom(false);

        this.header.leftButton.setIcon("update");
        this.header.title.setTitle(loc("My feed"));
    }


    this.ConversationsView = new (function(parent) {

        this.parent = parent;
        this.element = e("div", "toolbox").appendTo(parent.content);

        this.active = false;

        this.erase = function() {
            for (var i in this.snaps)
                this.snaps[i].remove();

            this.snaps = new Array();
        }

        this.close = function() {
            this.erase();
            this.active = false;
            this.parent.header.rightButton.show();
        }
        this.setConv = function(conv) {

            this.active = true;
            this.parent.header.rightButton.hide();

            this.element.scrollTop(0);

            for (var k in conv.snaps) {
                var snap = conv.snaps[k];

                var element = this.snapElement(snap)
                				  .appendTo(this.element);

                snap.element = element;

                snap.change(function(snap) {
                    if (!snap.url)
                        snap.element.addClass("hide");
                    else
                        snap.element.children(".img").css("background-image", "url('" + snap.url + "')");
                });

                this.snaps.push(snap.element);
            }


            this.parent.header.title.setTitle(loc("Conversation with %@", conv.users.join(", ")));

            var feedPage = this.parent;
            feedPage.content.data('scrollTop', feedPage.content.scrollTop());
            feedPage.content.scrollTop(0);
            feedPage.zoom(true);
        }

        this.snapElement = function(snap) {
            var el = e("div", "snap"),
            	friend = SnappyUI.updates.Friends.friendByName(snap.user),
				userText = e("p", 0, (friend ? friend.displayName : snap.user)),
				iconDiv = e("p"),
				mediaType = snap.mediaType,
				img = e("div", "img").appendTo(el);

            function icon(icon) {
                return e("span", "icon", icon);
            }

            if (mediaType.isFriendRequest)
                iconDiv.append(icon(""));
            else
                iconDiv.append(icon(snap.received ? "8" : "9"));

            if (mediaType.isImage)
                iconDiv.append(icon(""));
            if (mediaType.isVideo)
                iconDiv.append(icon(""));
            if (mediaType.isAudio)
                iconDiv.append(icon("z"));

            userText.appendTo(el);
            iconDiv.appendTo(el);

            e("p", 0, loc("%@ ago", snap.date.timeSince())).appendTo(el);

            if (snap.mediaType.isFriendRequest)
                e("p", "acceptFriend", loc("Accept")).appendTo(el)
                									 .click(function() {
	                $(this).data("friend").acceptRequest();
	            });

            el.attr("data-media-type", snap.mediaType.id);

            if (snap.url)
                img.css("background-image", "url('"+snap.url+"')");

            el.data("snap", snap)
              .click(function() {
                  var snap = $(this).data("snap");
                  if (snap)
                      snap.show();
              });

            return el;
        }

        this.erase();

        return this;
    })(this);


    this.setConversations = function(conversations) {
        this.erase();
        for (var i in conversations.conversations) {
            var conv = conversations.conversations[i];

            this.conversations[conv.id] = conv;
        }

        this.update();
    }
    this.conversationElement = function(conv) {
        var el = e("div", "conversation"),
	        nSnap = conv.snaps.length,
	        nMsg = conv.messages.length,
	        details = e("p", "details"),
	        snapRect = e("div", "snapRect"),
	        _this = this;

        if (conv.msgUnread)
            snapRect.addClass("messages");
        else if (conv.snapsUnread)
            snapRect.addClass("snaps");

        e("p", 0, conv.users.join(" + ")).appendTo(el);
        snapRect.appendTo(el);
        details.appendTo(el);

        if (nSnap) {
            var snapEl = e("span", "snapText", nSnap).appendTo(details)
            .prepend(e("span", "icon", ""));
            if (conv.snapsUnread)
                snapEl.append(e("span", "new", conv.snapsUnread));
        }
        if (nMsg) {
            var msgEl = e("span", "msgText", nMsg).appendTo(details)
            .prepend(e("span", "icon", "w"));
            if (conv.msgUnread)
                msgEl.append(e("span", "new", conv.msgUnread));
        }
        if (conv.duration)
            e("span", 0, conv.duration + "s").appendTo(details)
            .prepend(e("span", "icon", "}"));

        e("span", 0, conv.lastInteraction.timeSince()).appendTo(details)
        .prepend(e("span", "icon", ""));

        var snaps = conv.snaps;
        for (var i in snaps) {
            var snap = snaps[i];

            if (snap.url) {
                var img = e("img").attr("src", snap.url);
                img.appendTo(el);
            } else {
                snap.change(function(snap) {
                    var img = e("img").attr("src", snap.url);
                    img.appendTo(el);
                });
            }
        }

        el.data("conv", conv);
        
        if(nSnap)
        	el.click(function() {
				var conv = $(this).data("conv");
		        SnappyUI.FeedPage.ConversationsView.setConv(conv);
				SnappyUI.FeedPage.zoom(true);
		    });

        return el;
    }

    this.update = function() {
        for (var id in this.conversations) {
            var conversation = this.conversations[id];

            if (conversation.element)
                continue;

            conversation.element = this.conversationElement(conversation);
            conversation.element.appendTo(this.content);
        }

    }

    this.erase();

    return this;
}

