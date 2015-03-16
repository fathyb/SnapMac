function Settings(parent) {
	var _this = this;
	
	this.parent = parent;
	
	this.element = e("div", "settingsView").appendTo(parent.body);
	
	this.content = e("div", "content").appendTo(this.element);
	
	this.closeBtn = e("button", "icon close", "M").appendTo(this.content)
									   .click(function() {
										   _this.close();
									   });
	this.title = e("p", "title", loc("Profil settings")).appendTo(this.content);
	
	this.show = function() {
		this.parent.currentPage.blur(true);
		this.element.addClass("show");
	}
	this.close = function() {
		this.parent.currentPage.blur(false);
		this.element.removeClass("show");
	}
}