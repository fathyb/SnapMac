function SendPage(parent) {
	
	var _this = this;
	this.parent = parent;
    this.onlyShowIfLogged = true;

    this.parent.Section(this, "sendPage");

    this.header.element.hide();

    this.showed = function() {
        this.precPage = this.parent.currentPage;
        this.parent.toggleCam.element.hide();
    }
    this.hidden = function() {
        if (this.precPage)
            this.precPage.show(true);

        this.parent.toggleCam.element.show();
    }


    this.friendList = e("div", "friendList");
    this.friendList.appendTo(this.element);

    var el = e("div").addClass("story")
    .data("friend", "story"),
    check = e("div", "check").appendTo(el),
    sendFriend = e("div", "sendFriend").appendTo(el);


    el.click(function() {
        toggleClass($(this).children(".check"), "clicked");
        var nbrAmis = $(".friendList .clicked").length;
        $('.selectedFriendNum').text(nbrAmis);
    });

    e("p", 0, loc("My Story")).appendTo(sendFriend);

    el.appendTo(this.friendList);
    this.erase = function() {
        for (var i in this.friendElements)
            this.friendElements[i].remove();

        this.friends = new Object();
        this.friendElements = new Object();
    }
    this.setFriends = function(friends) {
        this.erase();
        this.friends = friends;
        this.update();
    }

    this.search = function(str) {
        var friends = this.friends.searchFriend(str);

        if (!str)
            return this.friendList.children("div").show();

        this.friendList.children("div").hide();

        var jFriends = new Object();

        for (var i in friends) {
            var friend = friends[i];

            this.friendElements[friend.name].show();
        }

    }

    this.update = function() {
        for (var i in this.friends.friends) {
            var friend = this.friends.friends[i];

            if (!this.friendElements[friend.name]) {
                var el = e("div").data("friend", friend),
                check = e("div", "check").appendTo(el),
                sendFriend = e("div", "sendFriend").appendTo(el);

                el.click(function() {
                    toggleClass($(this).children(".check"), "clicked");
                    var nbrAmis = $(".friendList .clicked").length;
                    $('.selectedFriendNum').text(nbrAmis);
                });

                e("p", 0, friend.displayName).appendTo(sendFriend);
                e("p", 0, friend.name).appendTo(sendFriend);

                el.appendTo(this.friendList);
                this.friendElements[friend.name] = el;
            }

        }
    }

    this.erase();

    this.SendActions = new (function(parent) {
	    var _this = this;
		this.parent = parent;
        this.element = e("div", "sendPageActions").appendTo(parent.element);

        this.cancelBtn = e("button", "cancel", loc("Cancel")).appendTo(this.element);
        this.selectBtn = e("button", "select").appendTo(this.element);
        this.sendBtn = e("button", "send", loc("Send")+" (").appendTo(this.element);
        this.shareBtn = e("button", "share", loc("Share")).appendTo(this.element);
        this.saveBtn = e("button", "save", loc("Save")).appendTo(this.element);

        this.checkBtn = e("div", "check").appendTo(this.selectBtn);

        this.selectedCount = e("span", "selectedFriendNum", "0");
        this.sendBtn.append(this.selectedCount)
        .append(")");

        this.cancelBtn.click(function() {
            _this.parent.hide();
            SnapJS.switchToPhotoMode();
        });
        this.sendBtn.click(function() {
            var friends = new Array();

            _this.parent.friendList.children("div").each(function() {
                if ($(this).children(".check").hasClass("clicked")) {
                    var friend = $(this).data("friend");

                    friends.push(friend == "story" ? "story" : friend.name);
                }
            });

            _this.parent.parent.LoadingPage.show();
            SnapJS.sendSnap(friends, function(result) {
                _this.parent.parent.LoadingPage.hide();
                if (result) {
                    _this.cancelBtn.click();
                }
            });
        });
        this.selectBtn.click(function() {

            var checkBtn = _this.checkBtn;
            if (checkBtn.hasClass('checked')) {
                $('.friendList>div .check:visible').removeClass('clicked');
                checkBtn.removeClass('checked');
            } else {
                $('.friendList>div .check:visible').addClass('clicked');
                checkBtn.addClass('checked');
            }
            var nbrAmis = $(".friendList .clicked").length;
            $('.selectedFriendNum').text(nbrAmis);
        });

        return this;
    })(this);

    return this;
}

