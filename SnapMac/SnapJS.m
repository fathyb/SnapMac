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
	return uuidString;
}

NSError *nserror(NSInteger code, NSString *message) {
	return [NSError errorWithDomain:@"com.fathyb.snappy" code:code userInfo:@{@"NSLocalizedDescription":message}];
}

NSDictionary *jsError(id error) {
	NSString *message = ((NSError*)error).userInfo[@"NSLocalizedDescription"];
	NSInteger code	  = ((NSError*)error).code;
	
	return @{ @"error": @{
					  @"code": @(code),
					  @"message": message ? message : @"Erreur inconnue"
					  }
			  };
}
id AFError(NSError *error, BOOL forJS) {
	NSInteger code = SnappyErrorUnknowError;
	NSString *message = [NSString stringWithFormat:@"Erreur de connection inconnue! (e%ld)", (long)error.code];
	
	switch (error.code) {
		case -1011:
			code = SnappyErrorNotAuthorized;
			message = @"Non authorisé";
			break;
		default:
			break;
	}
	
	return forJS ? jsError(nserror(code, message)) : nserror(code, message);
}
BOOL isError(id obj) {
	if(!obj)
		return NO;

	return [obj isKindOfClass:[NSError class]];
}


@implementation SnapJS

#pragma mark Base

-(SnapJS*)init {
	if(SnapJSSharedInstance)
		return SnapJSSharedInstance;
	if(self = [super init]) {
		NSDictionary *dict = @{
							   @"ShowingCamera": @"showingCamera",
							   @"ClosingCamera": @"closingCamera",
							   @"SnappySettingsLoaded": @"settingsLoaded:",
							   @"SnappyUse3D": @"use3D:",
							   @"SnappyUseParallax": @"useParallax:",
							   };
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		for(NSString* notifName in dict.allKeys)
			[center addObserver:self
					   selector:NSSelectorFromString(dict[notifName])
						   name:notifName
						 object:nil];
		
		_opQueue = [NSOperationQueue new];
	}
	SnapJSSharedInstance = self;
	return self;
}

#pragma mark Comptes et connection
-(void)setUsername:(NSString *)username {
	[[SMSettings sharedInstance] setObject:username forKey:@"SMUsername"];
	_username = username;
}
-(void)setAuthToken:(NSString *)authToken {
	[[SMSettings sharedInstance] setObject:authToken forKey:@"SMAuthToken"];
	_authToken = authToken;
}
-(void)settingsLoaded:(NSNotification*)notification {
	_username = [[SMSettings sharedInstance] objectForKey:@"SMUsername"];
	_authToken = [[SMSettings sharedInstance] objectForKey:@"SMAuthToken"];
	int maxPdl = [[[SMSettings sharedInstance] objectForKey:@"SMMaxPDL"] intValue];
	_opQueue.maxConcurrentOperationCount = maxPdl > 1 ? maxPdl : 5;
	
	NSLog(@"_opQueue max = %d", _opQueue.maxConcurrentOperationCount);
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
			if([result isKindOfClass:[NSDictionary class]]) {
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
				callback(nserror(SnappyErrorFailedToConnect, @"Impossible de se connecter à Snapchat!"));
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
	ContexteJS = webView.mainFrame.globalContext;
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
		@"sendSnapTo:withMedia:": @"sendSnap",
		@"loginWithUser:password:andCallback:": @"login",
		@"openURL:": @"openURL",
		@"testCallback:": @"testCallback",
		@"notification:withMessage:andCallback:": @"notification"
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
	
	if(method == SnappyMethodPOST) {
		parameters = [SMConnection genericDataWithToken:_authToken];
		parameters[@"username"] = _username;
		
		
		if(data) {
			if(data[@"username"])
				parameters = [SMConnection genericData];
			
			for(NSString *key in data.allKeys)
				parameters[key] = data[key];
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
			
			callback(error ? [NSString stringWithUTF8String:responseObject.bytes] : json);
		}
	};
	void (^failureBlock)() = ^(AFHTTPRequestOperation *operation, NSError *error) {
		
		callback(AFError(error, YES));
	};
	
	
	
	NSError				*error	 = nil;
	NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@(method == SnappyMethodPOST ? "POST" : "GET")
																				 URLString:api(url)
																				parameters:parameters
																					 error:&error];
	
	[request setValue:@"Snapchat/"SNAPCHAT_VERSION" (iPhone; iOS 8.1.1; gzip)"
   forHTTPHeaderField:@"User-Agent"];
	
	
	AFHTTPRequestOperation *manager = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	
	[manager setCompletionBlockWithSuccess:successBlock
								   failure:failureBlock];
	
	[_opQueue addOperation:manager];
	
}

#pragma mark API

-(void)showCamera {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SnappyShowCamera"
														object:@YES];
}
-(void)hideCamera {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SnappyShowCamera"
														object:@NO];
}
-(void)showMedia:(NSString*)media {
	[SMFileCollector urlsForMedia:media andCallback:^(NSDictionary* urls) {
		if(!urls)
			return;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SnappyShowMedia"
															object:urls];
	}];
}
-(void)sendSnapTo:(NSString*)to withMedia:(NSString*)mediaPath andCallback:(WebScriptObject*)callback {
	
	NSImage *media = [[NSImage alloc] initWithContentsOfFile:mediaPath];
	
	if([media isKindOfClass:[NSImage class]]) {
		
		NSString *guuid	  = [NSString stringWithFormat:@"%@~%@", _username.uppercaseString, UUID().lowercaseString];
		NSData	 *imgData = [(NSImage*)media dataForFileType:NSJPEGFileType];
		NSData	 *data	  = [SMCrypto encryptSnap:imgData];
		
		if(data) {
			[self requestTo:@"/bq/upload"
				   withData:@{
								@"username"	: _username,
								@"media_id"	: guuid,
								@"type"		: @0,
								@"data"		: data
							}
				andCallback:^(NSString *result) {
								if(isError(result))
									[callback call:jsError(result), nil];
								else if(!result.length || [result isEqualToString:@""]) {
								   
									[self requestTo:@"/bq/send"
										  withData:@{
													 @"media_id" : guuid,
													 @"recipient": to,
													 @"time"	 : @5,
													 @"zipped"   : @0
													}
									   andCallback:^(NSString *result) {
										   if(isError(result)) {
											   [callback call:jsError(result), nil];
										   }
										   
										   if(!result.length || [result isEqualToString:@""]) {
											   NSLog(@"YOUPIIIIII");
										   }
									   }];
					
								   return;
								}
						   }];
		}
		else {
			//callback(nil);;
		}
	}
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
				else if([result isKindOfClass:[NSData class]]) {
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
				else if([result isKindOfClass:[NSData class]]) {
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
		[[NSWorkspace sharedWorkspace] selectFile:url
						 inFileViewerRootedAtPath:url.stringByDeletingLastPathComponent];
	});
}
-(void)openURL:(NSString*)urlString {
	NSURL* url = [NSURL URLWithString:urlString];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

-(void)notification:(NSString*)title withMessage:(NSString*)message andCallback:(WebScriptObject*)callback {
	SnappyNotification *notif = [SnappyNotification new];
	notif.title = @"Snappy";
	notif.subtitle = title;
	notif.informativeText = message;
	notif.hasActionButton = YES;
	notif.actionButtonTitle = @"Test";
	
	[[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notif];
}
-(BOOL)use3D {
	return _use3D;
}
-(BOOL)useParallax {
	return _useParallax;
}
-(void)switchToPhotoMode {
	SMCamView *camView = [[[NSApplication sharedApplication] delegate] performSelector:@selector(camView)];
	[camView cleanStart];
}

#pragma mark API Objective-C
-(void)hideSend {
	[self scriptTS:@"SnappyUI.hideSend();"];
}

-(void)showingCamera {
	[self scriptTS:@"SnappyUI.toggleCam.setIcon('hide');"];
}
-(void)closingCamera {
	[self scriptTS:@"SnappyUI.toggleCam.setIcon('show');"];
}

-(id)script:(NSString*)command {
	return [_webView.windowScriptObject evaluateWebScript:command];
}
-(void)scriptTS:(NSString*)command {
	[_webView.windowScriptObject performSelectorOnMainThread:@selector(evaluateWebScript:)
												  withObject:command
											   waitUntilDone:NO];
}

-(void)use3D:(NSNotification*)notif {
	_use3D = [[notif object] boolValue];
	NSString *cmd = [NSString stringWithFormat:@"SnappyUI.use3D(%@);", @(_use3D ? "true" : "false")];
	[self scriptTS:cmd];
}
-(void)useParallax:(NSNotification*)notif {
	_useParallax = [[notif object] boolValue];
	NSString *cmd = [NSString stringWithFormat:@"SnappyUI.useParallax(%@);", @(_useParallax ? "true" : "false")];
	[self scriptTS:cmd];
}

@end
