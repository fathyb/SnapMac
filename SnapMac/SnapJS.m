//
//  SnapJS.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 11/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>
#import "SnapJS.h"
#import "SMCamView.h"
#import "Snappy.h"
#import "AFNetworking/AFNetworking.h"
#import "SMCrypto.h"
#import "SMFileCollector.h"
#import "NSData+Base64.h"
#import "SSKeychain.h"
#import "SMConnection.h"


static SnapJS *SnapJSSharedInstance;

NSString *api(NSString *url) {
	return [NSString stringWithFormat:@"https://feelinsonice-hrd.appspot.com%@", url];
}

NSString *UUID() {
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
	CFRelease(uuid);
	return uuidString.lowercaseString;
}

NSError *nserror(NSInteger code, NSString *message) {
	return [NSError errorWithDomain:@"com.fathyb.snappy"
							   code:code
						   userInfo:@{@"NSLocalizedDescription":message ? message : @""}];
}

NSDictionary *jsError(id error) {
	NSString *message = ((NSError*)error).userInfo[@"NSLocalizedDescription"];
	NSInteger code	  = ((NSError*)error).code;
	
	return @{ @"error": @{
					  @"code": @(code),
					  @"message": message ? message : NSLoc(@"Unknown error")
					  }
			  };
}
id AFError(NSError *error, BOOL forJS) {
	NSInteger code = SnappyErrorUnknowError;
	NSString *message = [NSString stringWithFormat:NSLoc(@"An unknown connection error occurred. (e%ld)"), (long)error.code];
	
	return forJS ? jsError(nserror(code, message)) : nserror(code, message);
}
BOOL isError(id obj) {
	if(!obj)
		return NO;

	return [obj isKindOfClass:NSError.class];
}


@implementation SnapJS

#pragma mark Base

-(SnapJS*)init {
	if(SnapJSSharedInstance)
		return SnapJSSharedInstance;
	if(self = [super init]) {
		NSDictionary *dict = @{
							   @"ShowingCamera": @"showingCamera:",
							   @"ClosingCamera": @"closingCamera:",
							   @"SnappySettingsLoaded": @"settingsLoaded:",
							   @"SnappyUse3D": @"use3D:",
							   @"SnappyUseParallax": @"useParallax:",
							   @"SnappyHideFeedPics": @"hideFeedPics:",
							   @"SnappyTakePhoto": @"showSend:",
							   @"SnappyChangeAppearance": @"changeAppearance:",
							   @"SnappyClearUserFeed": @"clearUserFeed:"
							   };
		NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
		for(NSString* notifName in dict.allKeys)
			[center addObserver:self
					   selector:NSSelectorFromString(dict[notifName])
						   name:notifName
						 object:nil];
		_androSync = SMAndroidSync.new;
		_opQueue = NSOperationQueue.new;
	}
	SnapJSSharedInstance = self;
	return self;
}

#pragma mark Comptes et connection
-(void)setUsername:(NSString *)username {
	[Settings.sharedInstance setObject:username forKey:@"SMUsername"];
	_username = username;
}
-(void)setAuthToken:(NSString *)authToken {
	[Settings.sharedInstance setObject:authToken forKey:@"SMAuthToken"];
	_authToken = authToken;
}
-(void)loginWithUser:(NSString*)user password:(NSString*)password andCallback:(WebScriptObject*)callback {
	[self testLogin:user
		   password:password
		andCallback:^(id result) {
			BOOL error	 = isError(result);
				 _logged = !error;
			
			[callback call:error ? jsError(result) : result, nil];
	}];
}

-(void)testLogin:(NSString*)login password:(NSString*)password andCallback:(SMCallback)callback {
	[self requestTo:@"/loq/login"
		   withData:@{
					  @"username": login,
					  @"password": password
					}
		andCallback:^(id result) {
			if([result isKindOfClass:NSDictionary.class]) {
				NSDictionary *rep = result[@"updates_response"];
				
				if(!rep) {
					NSString *message = nil;
					SnappyError error = SnappyErrorUnknowError;
					
					error = [@{
							   @(-100) : @(SnappyErrorBadPassword),
							   @(-101) : @(SnappyErrorBadUsername)
							}[result[@"status"]] integerValue];
					
					message = result[@"message"];
					
					callback(nserror(error, message));
				}
				else {
					self.authToken = rep[@"auth_token"];
					self.username  = rep[@"username"];
					callback(@{
							   @"updates": result
							});
				}
			}
			else {
				callback(nserror(SnappyErrorFailedToConnect, NSLoc(@"Can't establish connection to Snapchat.")));
			}
	}];
}
-(void)testWithCallback:(SMCallback)callback {
	[self requestTo:@"/bq/updates" withCallback:^(id result) {
			callback(result);
	}];
}

#pragma mark WebKit
-(void)setWebView:(SMWebUI*)webView {
	_webView = webView;
	SMJSContext = webView.mainFrame.globalContext;
}
+(NSString*)webScriptNameForSelector:(SEL)sel {
	NSDictionary *selectors = @{
		@"getSnap:withCallback:": @"getSnap",
		@"showInFinder:": @"showInFinder",
		@"getKeychainWithCallback:": @"getKeychain",
		@"showMedia:": @"showMedia",
		@"getStory:withKey:iv:andCallback:": @"getStory",
		@"getUpdates:": @"getUpdates",
		@"getStories:": @"getStories",
		@"sendSnapTo:withCallback:": @"sendSnap",
		@"loginWithUser:password:andCallback:": @"login",
		@"openURL:": @"openURL",
		@"testCallback:": @"testCallback",
		@"notification:withMessage:andCallback:": @"notification",
		@"localizedString:": @"locale"
	};
	for(NSString *selName in selectors) {
		if(NSSelectorFromString(selName) == sel) return selectors[selName];
	}
	return nil;
}

+(BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
	return NO;
}

#pragma mark HTTPS

-(void)requestTo:(NSString*)url withCallback:(SMCallback)callback {
	[self requestTo:url
		   withData:nil
		andCallback:callback
			 asData:NO
			 method:SnappyMethodPOST];
}
-(void)requestTo:(NSString*)url withData:(NSDictionary*)data andCallback:(SMCallback)callback {
	[self requestTo:url
		   withData:data
		andCallback:callback
			 asData:NO
			 method:SnappyMethodPOST];
}
-(void)requestTo:(NSString*)url withData:(NSDictionary*)data andCallback:(SMCallback)callback asData:(BOOL)asData {
	[self requestTo:url
		   withData:data
		andCallback:callback
			 asData:asData
			 method:SnappyMethodPOST];
}
-(void)requestTo:(NSString*)url withData:(NSDictionary*)data andCallback:(SMCallback)callback asData:(BOOL)asData method:(SnappyMethod)method{
	
	if(!_username)
		_username = @"";
	
	NSMutableDictionary *parameters = nil;
	BOOL multipart = NO;
	NSData *rawData = nil;
	
	if(method == SnappyMethodPOST) {
		parameters = [SMConnection genericDataWithToken:_authToken];
		parameters[@"username"] = _username;
		
		if(data) {
			if(data[@"username"])
				parameters = SMConnection.genericData;
			
			for(NSString *key in data.allKeys) {
				id obj = data[key];
				
				if([obj isKindOfClass:NSData.class]) {
					multipart = YES;
					rawData = obj;
					continue;
				}
				parameters[key] = obj;
			}
		}
	}
	else
		parameters = data.mutableCopy;
	
	void (^successBlock)() = ^(AFHTTPRequestOperation *operation, NSData *responseObject) {
		
		if(asData) {
			callback(responseObject);
		}
		else {
			NSError  *error = nil;
			NSString *json  = [NSJSONSerialization JSONObjectWithData:responseObject
															  options:kNilOptions
																error:&error];
			const void *bytes = responseObject.bytes;
			
			if(!bytes)
				callback(@YES);
			else
				callback(error ? [NSString stringWithUTF8String:bytes] : json);
		}
	};
	void (^failureBlock)() = ^(AFHTTPRequestOperation *operation, NSError *error) {
		callback(AFError(error, YES));
	};
	
	
	
	NSError				*error	 = nil;
	NSMutableURLRequest *request = nil;
	if(multipart)
		request = [AFHTTPRequestSerializer.serializer multipartFormRequestWithMethod:@"POST"
																		   URLString:api(url)
																		  parameters:parameters
														   constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
															   [formData appendPartWithFileData:rawData
																						   name:@"data"
																					   fileName:@"snap"
																					   mimeType:@"image/jpeg"];
														   }				   error:&error];
	else
		request = [AFHTTPRequestSerializer.serializer requestWithMethod:@(method == SnappyMethodPOST ? "POST" : "GET")
															  URLString:api(url)
															 parameters:parameters
																  error:&error];
	
	[request setValue:@"Snapchat/"SNAPCHAT_VERSION" (iPhone; iOS 8.1.1; gzip)"
   forHTTPHeaderField:@"User-Agent"];
	
	
	AFHTTPRequestOperation *manager = [AFHTTPRequestOperation.alloc initWithRequest:request];
	
	[manager setCompletionBlockWithSuccess:successBlock
								   failure:failureBlock];
	
	[_opQueue addOperation:manager];
	
}

#pragma mark API

-(void)clearSearchField {
	[NSNotificationCenter.defaultCenter postNotificationName:@"SnappyClearSearchField"
													  object:nil];
}
-(NSString*)localizedString:(NSString*)key {
	return NSLocalizedString(key, nil);
}
-(void)showCamera {
	[NSNotificationCenter.defaultCenter postNotificationName:@"SnappyShowCamera"
														object:@YES];
}
-(void)hideCamera {
	[NSNotificationCenter.defaultCenter postNotificationName:@"SnappyShowCamera"
														object:@NO];
}
-(void)showMedia:(NSString*)media {
	[SMFileCollector urlsForMedia:media andCallback:^(NSDictionary* urls) {
		if(!urls)
			return;
		
		[NSNotificationCenter.defaultCenter postNotificationName:@"SnappyShowMedia"
														  object:urls];
	}];
}
-(void)sendSnapTo:(WebScriptObject*)to withCallback:(WebScriptObject*)callback {
	
	id recp = to.toObjCObject;
	
	BOOL multiPost = NO;
	BOOL coma = NO;
	
	NSMutableString *recpString = NSMutableString.new;
	
	for(id k in recp) {
		NSString *user = recp[k];
		if([user isEqualToString:@"story"])
			multiPost = YES;
		else {
			[recpString appendFormat:@"%@%@", coma ? @"," : @"", user];
			coma = YES;
		}
	}
	
	NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
	[nc addObserverForName:@"SnappyIGotPhoto"
					object:nil
					 queue:NSOperationQueue.mainQueue
				usingBlock:^(NSNotification *note) {
					
					NSImage *media	  = note.object;
					if(!media)
						return [callback call:@{
												@"error": NSLoc(@"No image to send")
											  }, nil];
		
					NSString *guuid	  = [NSString stringWithFormat:@"%@~%@", self.username.uppercaseString, UUID()];
					NSData	 *imgData = [media dataForFileType:NSJPEGFileType];
					NSData	 *data	  = [SMCrypto encryptSnap:imgData];
		
					if(data) {
						[self requestTo:@"/bq/upload"
							   withData:@{
										  @"media_id"	: guuid,
										  @"type"		: @0,
										  @"data"		: data,
										  @"zipped"		: @0
										}
							andCallback:^(NSString *result) {
								
								if(isError(result))
									[callback call:jsError(result), nil];
					
								else {
									NSMutableDictionary *data = @{
																  @"media_id" : guuid,
																  @"recipient": recpString,
																  @"time"	  : @5
																 }.mutableCopy;
									if(multiPost)
										[data setValuesForKeysWithDictionary:@{
																			   @"client_id": guuid,
																			   @"caption_text_display": @""
																			 }];
										
									[self requestTo:@(multiPost ? "/bq/double_post" : "/bq/send")
										   withData:data
										andCallback:^(NSError *result) {
											[callback call:result, nil];
										}];
								}
						   }];
					}
					else {
						[callback call:jsError(nserror(25, @"No Image")), nil];
					}
		
	}];
	[nc postNotificationName:@"SnappyNeedPhoto"
					  object:nil];
}
-(void)getSnap:(NSString*)snapid withCallback:(WebScriptObject*)callback {
	[SMFileCollector urlsForMedia:snapid andCallback:^(NSDictionary* urls) {
		if(urls)
			return [callback call:urls, nil];
		
		[self requestTo:@"/ph/blob"
			   withData:@{
						  @"id": snapid
						}
			andCallback:^(id result) {
				if(isError(result)) {
					[callback call:jsError(result), nil];
				}
				else if([result isKindOfClass:NSData.class]) {
					NSData *decryptedSnap = [SMCrypto decryptSnap:result];
					if(isError(decryptedSnap)) {
						[callback call:jsError(decryptedSnap), nil];
					}
					else {
						[SMFileCollector save:snapid
									 withData:decryptedSnap
								  andCallback:^(NSDictionary* urls) {
									  if(!urls)
										  [callback call:jsError(nserror(-20, @"Erreur lors de l'enregistrement d'un snap")), nil];
									  else
										  [callback call:urls, nil];
								  }];
					}
				}
			} asData:YES];
	}];
}
-(void)getStory:(NSString*)identifier withKey:(NSString*)keyString iv:(NSString*)ivString andCallback:(WebScriptObject*)callback {
	[SMFileCollector urlsForMedia:identifier andCallback:^(NSDictionary* urls) {
		
		if(urls)
			return [callback call:urls, nil];
		
		NSData *key = [NSData dataFromBase64String:keyString];
		NSData *iv	= [NSData dataFromBase64String:ivString];
		
		[self requestTo:@"/bq/story_blob"
			   withData:@{
						  @"story_id": identifier
						  }
			andCallback:^(NSData *result) {
				
				if(isError(result)) {
					[callback call:jsError(result), nil];
				}
				else if([result isKindOfClass:NSData.class]) {
					NSData *decryptedStory = [SMCrypto decryptStory:result
															withKey:key
															  andIv:iv];
					
					if(isError(decryptedStory))
						[callback call:jsError(decryptedStory), nil];
					else
						[SMFileCollector save:identifier
									 withData:decryptedStory
								  andCallback:^(NSDictionary *urls) {
									  [callback call:urls, nil];
								  }];
				}
			}
				 asData:YES
				 method:SnappyMethodGET];
	}];

}
-(void)getUpdates:(WebScriptObject*)callback {
	[self requestTo:@"/loq/all_updates"
		   withData:@{}
		andCallback:^(id result) {
		if(isError(result))
			[callback call:AFError(result, YES), nil];
		else
			[callback call:result, nil];
	}];
}
-(void)logout {
	self.authToken = @"";
	self.username  = @"";
	self.logged    = NO;
}
-(void)getKeychainWithCallback:(WebScriptObject*)callback {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError		 *error	  = nil;
		NSDictionary *account = [SSKeychain accountsForService:@"SnapMac"][0];
		NSString	 *pass	  = [SSKeychain passwordForService:@"SnapMac"
													   account:account[@"acct"]
														 error:&error];
		
		if(error)
			[callback call:jsError(nserror(200, @"Erreur lors de l'accès aux trousseau de clés")), nil];
		else
			[callback call:@{
							 @"login": account[@"acct"],
							 @"pass" : pass
							}, nil];
	});
}

-(void)showInFinder:(NSString*)url {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[NSWorkspace.sharedWorkspace selectFile:url
					   inFileViewerRootedAtPath:url.stringByDeletingLastPathComponent];
	});
}
-(void)openURL:(NSString*)urlString {
	NSURL* url = [NSURL URLWithString:urlString];
	[NSWorkspace.sharedWorkspace openURL:url];
}

-(void)notification:(NSString*)title withMessage:(NSString*)message andCallback:(WebScriptObject*)callback {
	SnappyNotification *notif = SnappyNotification.new;
	notif.title = @"Snappy";
	notif.subtitle = title;
	notif.informativeText = message;
	notif.hasActionButton = YES;
	notif.actionButtonTitle = @"Test";
	
	[NSUserNotificationCenter.defaultUserNotificationCenter scheduleNotification:notif];
}
-(BOOL)use3D {
	return _use3D;
}
-(BOOL)useParallax {
	return _useParallax;
}
-(void)switchToPhotoMode {
	SMCamView *camView = [NSApplication.sharedApplication.delegate performSelector:@selector(camView)];
	[camView cleanStart];
}
-(void)clearFeed {
	[NSNotificationCenter.defaultCenter postNotificationName:@"SnappyShowClearFeedDialog"
													  object:nil];
}


#pragma mark Notification Center
-(void)clearUserFeed:(NSNotification*)notif {
	[self requestTo:@"/ph/clear"
	   withCallback:^(id result) {
		   [self script:@"SnappyUI.update();"];
	}];
}
-(void)changeAppearance:(NSNotification*)notif {
	NSAppearance *appearance = notif.object;
	self.darkTheme = [appearance.name containsString:@"Dark"];
	[self script:[NSString stringWithFormat:@"SnappyUI.setTheme('%@');", self.darkTheme ? @"dark" : @"light"]];
}
-(void)showingCamera:(NSNotification*)notif {
	[self script:@"SnappyUI.toggleCam.setIcon('hide');"];
}
-(void)closingCamera:(NSNotification*)notif {
	[self script:@"SnappyUI.toggleCam.setIcon('show');"];
}
-(void)showSend:(NSNotification*)notif {
	[self script:@"SnappyUI.SendPage.show(true);"];
}
-(void)settingsLoaded:(NSNotification*)notification {
	Settings *settings = Settings.sharedInstance;
	_username = [settings objectForKey:@"SMUsername"];
	_authToken = [settings objectForKey:@"SMAuthToken"];
	int maxPdl = [[settings objectForKey:@"SMMaxPDL"] intValue];
	_opQueue.maxConcurrentOperationCount = maxPdl > 1 ? maxPdl : 5;
	
}
-(void)use3D:(NSNotification*)notif {
	_use3D = [notif.object boolValue];
	NSString *cmd = [NSString stringWithFormat:@"SnappyUI.use3D(%@);", @(_use3D ? "true" : "false")];
	[self script:cmd];
}
-(void)useParallax:(NSNotification*)notif {
	_useParallax = [notif.object boolValue];
	NSString *cmd = [NSString stringWithFormat:@"SnappyUI.useParallax(%@);", @(_useParallax ? "true" : "false")];
	[self script:cmd];
}
-(void)hideFeedPics:(NSNotification*)notif {
	_hideFeedPics = [notif.object boolValue];
	NSString *cmd = [NSString stringWithFormat:@"SnappyUI.hideFeedPics(%@);", @(_hideFeedPics ? "true" : "false")];
	[self script:cmd];
}

#pragma mark API Objective-C

-(void)script:(NSString *)command withCallback:(SMCallback)callback {
	dispatch_async(dispatch_get_main_queue(), ^{
		callback([_webView.windowScriptObject evaluateWebScript:command]);
	});
}
-(void)script:(NSString*)command {
	dispatch_async(dispatch_get_main_queue(), ^{
		[_webView script:command];
	});
}
-(void)hideSend {
	[self script:@"SnappyUI.hideSend();"];
}

-(void)controlTextDidChange:(NSNotification *)notif {
	NSSearchField *sfield = notif.object;
	
	[self.webView.windowScriptObject callWebScriptMethod:@"SnappySearchHandler"
										   withArguments:@[sfield.stringValue]];
	
	return;
}
@end
