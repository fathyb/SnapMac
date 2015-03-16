function LoadingPage() {

    this.element = e("div", "loadingView").appendTo("body");
    this.iconContent = e("div", "iconContent").appendTo(this.element);
    this.content = e("div", "content").appendTo(this.element);
    e("p", "icon", "").appendTo(this.iconContent);

    this.show = function() {
        this.element.addClass("active");
        SnappyUI.currentPage.blur(true);
    }
    this.hide = function() {
        this.element.removeClass("active");
        SnappyUI.currentPage.blur(false);
    }

    this.setTitle = function(title) {
        this.title.text(title);
    }
    this.title = function(title) {
        this.title.text(title);
    }
}

