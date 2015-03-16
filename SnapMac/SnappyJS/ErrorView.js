function ErrorView(parent) {
	this.element = e("div", "errorView").appendTo("body");
	this.errorIcon = e("span", "icon", "r").appendTo(this.element);
	this.errorText = e("p", "text").appendTo(this.element);
	this.closeBtn = e("span", "icon", "M").appendTo(this.element);
	this.parent = parent;
		
	var _this = this;
	this.closeBtn.click(function() {
		_this.hide();
	});
	this.unblur = false;
	this.show = function() {
		this.element.addClass("show");
	}
	this.hide = function() {
		this.element.removeClass("show");
			
		if(this.timeout) {
			clearTimeout(this.timeout);
		}
		if(this.unblur) {
			this.parent.currentPage.blur(false);
			this.unblur = false;
		}
	}
	this.showError = function(error) {
		if(error.code == 5) {
			error.message = loc("You have been disconnected");
		}
		this.errorText.text(error.message);
		if(error.blur) {
			this.parent.currentPage.blur(true);
			this.unblur = true;
		}
		this.show();
		
		var _this = this;
		this.timeout = setTimeout(function() {
			_this.hide();
		}, 10000);
	}
}