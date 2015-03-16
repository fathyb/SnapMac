function LoginPage() {

    SnappyUI.Section(this, "loginPage");

    this.header.title.setTitle(loc("Connection"));

    this.loginForm = e("form", "loginForm").appendTo(this.element);
    this.loginForm.submit(function() {
        return false;
    });

    this.inputLogin = e("input", {
        placeholder: loc("Username"),
        type: "text"
    }).appendTo(this.loginForm);

    this.inputPassword = e("input", {
        placeholder: loc("Password"),
        type: "password"
    }).appendTo(this.loginForm);

    this.connectBtn = e("button", 0, "Connection").appendTo(this.loginForm);

    this.connectBtn.click(function() {
        var username = SnappyUI.LoginPage.inputLogin.val(),
        password = SnappyUI.LoginPage.inputPassword.val(),
        leftButton = SnappyUI.LoginPage.header.leftButton;

        leftButton.setIcon("loading");
        leftButton.spin(true);

        Snappy.login(username, password, function(r) {

            if (r.error) {
                SnappyUI.ErrorView.showError(r.error);
                SnappyUI.logged = false;
                leftButton.spin(false);
                leftButton.setIcon(null);
            } else {
                SnappyUI.setUpdates(r);
                leftButton.spin(false);
                leftButton.setIcon(null);
            }
        });
    });


    this.iOSSync = new (function() {

        this.element = e("div", "iOSSync");


        this.header = new SnappyUI.Header(this);
        this.header.title.setTitle(loc("iOS Synchronization"));

        this.accountList = e("select").data("syncClass", this).appendTo(this.element)
        this.accountList.change(function() {
            $(this).data("syncClass").selectedBackup = $(this).children("option:selected").data("bid");
        });

        this.button = e("button", 0, loc("Connection")).appendTo(this.element);


        return this;

    })();

    this.iOSSync.element.appendTo(this.element);

    this.androSync = new (function() {

        this.element = e("div", "androSync");

        this.header = new SnappyUI.Header(this);
        this.header.title.setTitle(loc("Android Synchronization"));
        e("p", 0, loc("Please connect a rooted Android device with usb debugging enabled")).appendTo(this.element);

        this.error = e("p", "androidError");
        this.error.appendTo(this.element);

        this.button = e("button", 0, loc("Connection"));
        this.button.appendTo(this.element);
        this.button.click(function() {
            /*NEEEEEEEEEEEEEEEEEEEEED IMPLENTATION!!!!!!!!!!!!!!*/
            SnappyUI.LoginPage.androdSync.error.text("");
            $('body').addClass('loading');
            setTimeout(function() {
                if (!$('body').hasClass('loading')) 
                    return;
                $('body').removeClass('loading');
            }, 5000);
            SMClient.requestAndroidSync();
        });

        return this;

    })();

    this.androSync.element.appendTo(this.element);


    return this;
}

