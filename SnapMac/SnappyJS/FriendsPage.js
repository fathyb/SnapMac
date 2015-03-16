function FriendsPage() {

    this.onlyShowIfLogged = true;

    SnappyUI.Section(this, "friendsPage");

    this.header.leftButton.setIcon("update");
    this.header.rightButton.setIcon("settings");
    this.header.title.setTitle(loc("Friends"));

    this.content = e("div", "content").appendTo(this.element);
	
	this.search = function(str) {
		if(!str) {
			this.header.title.setTitle(loc("Friends"));
			$(this.friends).children(".friend").show();
		}
		else {
			this.header.title.setTitle(loc("Searching \"%@\"", str));
			$(this.friends).children(".friend").hide();
			
			var friends = this.friendList.searchFriend(str);
			for(var i in friends) {
				var friend = friends[i];
				if(friend.element)
					friend.element.show();
			}
		}
	}
	
    this.close = function() {
        this.StoriesView.close();
    }
	
	
    this.StoriesView = new (function(parent) {

        this.parent = parent;
        this.element = e("div", "toolbox")
        .appendTo(parent.content);

        this.active = false;
        this.erase = function() {
            for (var i in this.boxes)
                this.boxes[i].remove();

            this.stories = new Array();
            this.boxes = new Array();
        }

        this.boxes = new Array();

        this.updateFrame = function() {
            for (var i in this.boxes) {
                var box = this.boxes[i];

            }
        }
        this.close = function() {
            this.erase();
            this.active = false;
			var friendsPage = this.parent,
				header = friendsPage.header;
			
            friendsPage.content.scrollTop(SnappyUI.FriendsPage.content.data("scrollTop"));
            friendsPage.zoom(false);

            header.leftButton.setIcon("update");
            header.rightButton.show();
            header.title.setTitle(loc("Friends"));
        }
        this.setStories = function(stories) {
            this.active = true;

            this.element.scrollTop(0);

            for(var k in stories) {
                var story	  = stories[k],
                	storyBox  = e("div", "storyBox"),
					storyMage = e("div", "imgStory"),
					thumb	  = e("div", "thumb");
				
                thumb.appendTo(storyMage);
                storyMage.appendTo(storyBox).append(e("span", "icon", "="));
                
                e("p", 0, loc("%@ ago", story.date.timeSince())).appendTo(storyBox),
                e("span", "duration", story.duration + "s").appendTo(storyMage);

                if (story.mediaType.isVideo)
                    storyMage.addClass("video");

                storyBox.appendTo(this.element)
                		.addClass("loading").data({
							story: story,
							thumb: thumb
                		})
						.click(function() {
							var story = $(this).data("story");
							if (story)
								story.show();
						});
						
				story.box = storyBox;
				story.thumb = thumb;
                story.change(function(story) {
                    story.box.removeClass("loading");
                    story.thumb.css('background-image', story.image == "" ? "" : "url('" + story.image + "')");
                });
				story.load();
                    
				this.boxes.push(storyBox);
            }

			
            this.parent.header.title.setTitle(story.friend.isMe ? loc("My Story") : loc("%@'s story", story.friend.displayName));

            var friendsPage = this.parent;
            friendsPage.header.rightButton.hide();
            friendsPage.content.data('scrollTop', friendsPage.content.scrollTop());
            friendsPage.content.scrollTop(0);
            friendsPage.zoom(true);
        }

        return this;
    })(this);

    this.erase = function() {
        this.friendList = new Object();
        this.friends.children(".friend").remove();
        this.me.children(".friend").remove();
        this.events.children(".friend").remove();
    }
    this.friendList = new Object();

    this.setFriends = function(friendList) {
        this.erase();
        this.friendList = friendList;
        this.update();
    }


    this.friendElement = function(friend) {
        var el = e("div", "friend").data("friend", friend),
	        storiesBtn = e("p", "storiesBtn", loc("Stories")+" "),
	        numStories = e("span", "numStories").appendTo(storiesBtn).text(friend.stories.length ? "(" + friend.stories.length + ")" : ""),
	        displayDiv = e("div", "displayName").appendTo(el);


        e("input", 0).attr({
            type: "text",
            "placeholder": "Nom"
        }).val(friend.displayName)
          .appendTo(displayDiv)
          .keypress(function(event) {
              if(event.keyCode == '13')
                  toggleClass($(this).parent(), "edit");
        });

        e("p", 0, friend.displayName).appendTo(displayDiv).click(function(e) {
            toggleClass($(this).parent(), "edit");
        });
        e("p", "friendName", friend.name).appendTo(el);

        if (friend.isEvent) {
            e("p", 0, friend.place).appendTo(el)
            .prepend(e("span", "icon", ""))
            .click(function() {
                var friend = $(this).parent().data("friend");

                if (friend)
                    friend.showInMaps();
            });
        } else if (friend.stories.length) {
            var canvas = e("canvas");

        }

        storiesBtn.appendTo(el).click(function() {
            var friend = $(this).parent().data("friend"),
            	stories = friend.stories;

            if (!stories)
                return;

            SnappyUI.FriendsPage.StoriesView.setStories(stories);
        });


        return el;
    }
    
    
	this.me 	 = e("div", "me").appendTo(this.content);
	this.events  = e("div", "events").appendTo(this.content);
	this.friends = e("div", "friends").appendTo(this.content);
	e("h1", "title", loc("Me")).appendTo(this.me);
	e("h1", "title", loc("Events")).appendTo(this.events);
	e("h1", "title", loc("Friends")).appendTo(this.friends);
	
    this.update = function() {
	    var me = SnapJS.username();
        for(var name in this.friendList.friends) {
            var friend = this.friendList.friends[name];
            
            if (friend.element)
                continue;
				
            friend.element = this.friendElement(friend);
			
			if(friend.isMe)
				friend.element.appendTo(this.me);
			else if(friend.isEvent)
				friend.element.appendTo(this.events);
			else
            	friend.element.appendTo(this.friends);

        }
        if(this.events.children(".friend").length)
	        this.events.show();
	    else
	    	this.events.hide();
    }

    return this;
}


