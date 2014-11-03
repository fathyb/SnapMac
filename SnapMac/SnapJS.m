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
#import "SnapMac.h"
#import "AFNetworking/AFNetworking.h"
#import "SMCrypto.h"
#import "SMFileCollector.h"


static SnapJS* SnapJSSharedInstance;
BOOL use3D;

NSString* api(NSString *url) {
	return [NSString stringWithFormat:@"https://feelinsonice-hrd.appspot.com%@", url];
}

NSData* padData(NSData* data) {
	NSMutableData *tmpData		= data.mutableCopy;
	int blockSize				= 16;
	int charDiv					= blockSize - ((tmpData.length + 1) % blockSize);
	NSMutableString *padding	= [[NSMutableString alloc] initWithFormat:@"%c", (unichar)10];

	for (int c = 0; c < charDiv; c++) {
		[padding appendFormat:@"%c",(unichar)charDiv];
	}
	[tmpData appendData:[padding dataUsingEncoding:NSUTF8StringEncoding]];
	return tmpData;
}

NSError* nserror(NSInteger code, NSString* message) {
	return [NSError errorWithDomain:@"com.fathyb.snappy" code:code userInfo:@{@"NSLocalizedDescription":message}];
}

NSDictionary* jsError(NSError* error) {
	return @{ @"error": @{
					  @"code": @(error.code),
					  @"message": error.userInfo[@"NSLocalizedDescription"]
					  }
			  };
}
id AFError(NSError* error, BOOL forJS) {
	NSInteger code = SnappyErrorUnknowError;
	NSString* message = [NSString stringWithFormat:@"Erreur de connection inconnue! (e%ld)", (long)error.code];
	
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
	return [obj isKindOfClass:[NSError class]];
}


@implementation SnapJS

#pragma mark Base

-(SnapJS*)init {
	if(SnapJSSharedInstance)
		return SnapJSSharedInstance;
	if(self = [super init]) {
		[self logon];
	}
	SnapJSSharedInstance = self;
	return self;
}

#pragma mark Outils

-(SMCamView*)camView {
	SnapMac* delegate = (SnapMac*)[[NSApplication sharedApplication] delegate];
	return [delegate performSelector:@selector(camView) withObject:nil];
}

#pragma mark Comptes et connection

-(void)logon {
	_login = [[NSUserDefaults standardUserDefaults] objectForKey:@"SMLogin"];
	_authToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"SMAuthToken"];
	[self testWithCallback:^(id result) {
		if(isError(result)) {
			NSError *err = (NSError*)result;
			if(err.code == 3) {
				
			}
		}
		else {
			_logged = true;
		}
	}];
}

-(void)loginWithUser:(NSString*)user password:(NSString*)password andCallback:(NSString*)callback {
	[self testLogin:user
		   password:password
		andCallback:^(id result) {
		if(isError(result)) {
			_logged = NO;
			SnapCall(callback, jsError(result), nil);
		}
		else {
			_logged = YES;
			SnapCall(callback, result, nil);
		}
	}];
}

-(void)testLogin:(NSString*)login password:(NSString*)password andCallback:(SMCallback)callback {
	[self requestTo:@"/bq/login"
		   withData:@{@"username":login, @"password": password}
		andCallback:^(id result) {
			if([result isKindOfClass:[NSDictionary class]]) {
				NSDictionary *rep = (NSDictionary*)result;
				
				if([rep[@"logged"] isEqualToNumber:@0]) {
					NSString* message = nil;
					SnappyError error = SnappyErrorUnknowError;
					
					error = [@{
							   @(-100) : @(SnappyErrorBadPassword),
							   @(-101) : @(SnappyErrorBadUsername)
							  }[rep[@"status"]] integerValue];
					
					message = rep[@"message"];
					
					callback(nserror(error, message));
				}
				else {
					_authToken = rep[@"auth_token"];
					_login	   = rep[@"username"];
					callback(@{
							   @"updates": rep
							   });
				}
			}
			else {
				callback(nserror(SnappyErrorFailedToConnect, @"Impossible de se connecter à SnapChat!"));
			}
	}];
}
-(void)testWithCallback:(SMCallback)callback {
	[self requestTo:@"/bq/updates" withCallback:^(id result) {
			callback(result);
	}];
}

#pragma mark WebKit
-(void)setWso:(WebScriptObject *)wso {
	_wso = wso;
	SnapBackWSO = wso;
}
+(NSString*)webScriptNameForSelector:(SEL)sel {
	NSDictionary *selectors = @{
		@"getSnap:withCallback:": @"getSnap",
        @"getStory:withKey:iv:andCallback:": @"getStory",
		@"getUpdates:": @"getUpdates",
		@"getStories:": @"getStories",
		@"sendSnapTo:withMedia:": @"sendSnap",
		@"loginWithUser:password:andCallback:": @"login"
	};
	for(NSString* selName in selectors) {
		if(NSSelectorFromString(selName) == sel) return selectors[selName];
	}
	return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
	return NO;
}

#pragma mark HTTPS

-(void)requestTo:(NSString*)url withCallback:(SMCallback)callback {
	[self requestTo:url withData:nil andCallback:callback asData:NO];
}
-(void)requestTo:(NSString*)url withData:(NSDictionary*)data andCallback:(SMCallback)callback {
	
	[self requestTo:url withData:data andCallback:callback asData:NO];
}
-(void)requestTo:(NSString*)url withData:(NSDictionary*)data andCallback:(SMCallback)callback asData:(BOOL)asData {
	
	if(!_login) _login = @"";
	
	NSMutableDictionary *parameters				 = [SMConnection genericDataWithToken:_authToken];
						 parameters[@"username"] = _login;
	
	if(data) {
		if(data[@"username"]) {
			parameters = [SMConnection genericData];
		}
		for(NSString *key in data.allKeys) {
			parameters[key] = data[key];
		}
	}
	
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	
	[manager POST:api(url)
	   parameters:parameters
		  success:^(AFHTTPRequestOperation *operation, NSData* responseObject) {
			  if(asData) {
				callback(responseObject);
			  }
			  else {
				  NSError* error = nil;
				  NSString* json = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
				  if(!error)
					  callback(json);
				  else {
					  callback([NSString stringWithUTF8String:responseObject.bytes]);
					  
				  }
			  }
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		callback(AFError(error, YES));
	}];
}

#pragma mark API

-(void)showCamera {
	[[self camView] show];
}
-(void)hideCamera {
	[[self camView] hide];
}

-(NSString*)hasSnapSaved:(NSString*)snapid {
	return [self hasSnapSaved:snapid forNative:NO];
}
-(NSString*)hasSnapSaved:(NSString*)snapid forNative:(BOOL)native {
	NSFileManager *fManager = [NSFileManager defaultManager];
	NSArray *snaps = [fManager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/SnapMac/", NSHomeDirectory()] error:nil];
	for(NSString* snap in snaps) {
		if([snap hasPrefix:[NSString stringWithFormat:@"%@_thumb", snapid]] && !native) return [NSString stringWithFormat:@"%@/SnapMac/%@", NSHomeDirectory(), snap];
		if([snap hasPrefix:snapid] && !([snap hasSuffix:@"."] || ([snap hasSuffix:@".mp4"] && !native))) return [NSString stringWithFormat:@"%@/SnapMac/%@", NSHomeDirectory(), snap];
	}
	return nil;
}
-(void)sendSnapTo:(NSString*)to withMedia:(NSString*)mediaPath {
	
	NSImage* media = [[NSImage alloc] initWithContentsOfFile:mediaPath];
	
	if([media isKindOfClass:[NSImage class]]) {
		NSMutableDictionary *endPointData = [SMConnection genericDataWithToken:_authToken];
		endPointData[@"username"] = _login;
		endPointData[@"type"] = @"0";
		NSString *guuid = [NSString stringWithFormat:@"%@~%@", [_login uppercaseString], [[SMClient uuidString] lowercaseString]];
		endPointData[@"media_id"] = guuid;
		
		NSData *imgData = [(NSImage*)media dataForFileType:NSJPEGFileType];
		NSData *data = [SMCrypto encryptSnap:padData(imgData)];
		
		
		if(data) {
			endPointData[@"data"] = data;
			[SMConnection requestToURL:@"/bq/upload" withData:endPointData andCallback:^(NSString* result) {
				NSError *error = nil;
				if([result isKindOfClass:[NSError class]]) {
					error = (NSError*)result;
				}
				if(!result.length || [result isEqualToString:@""]) {
					NSMutableDictionary *endPointData = [SMConnection genericDataWithToken:_authToken];
					endPointData[@"username"] = _login;
					endPointData[@"media_id"] = guuid;
					endPointData[@"recipient"] = to;
					endPointData[@"time"] = @"5";
					endPointData[@"zipped"] = @"0";
				
					[SMConnection requestToURL:@"/bq/send" withData:endPointData andCallback:^(NSString* result) {
						NSError *error = nil;
						if([result isKindOfClass:[NSError class]]) {
							error = (NSError*)result;
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
-(void)getSnap:(NSString*)snapid withCallback:(Callback)callback {
	NSString *snap = [self hasSnapSaved:snapid];
	if(snap) {
		return SnapCall(callback, @{@"url": snap}, nil);
	}
	[self requestTo:@"/ph/blob" withData:@{
										   @"id": snapid
										   } andCallback:^(id result) {
											   
		if(isError(result)) {
			NSLog(@"Erreur! NSError = %@", result);
		}
		else if([result isKindOfClass:[NSData class]]) {
			NSData *decryptedSnap = [SMCrypto decryptSnap:result];
			if(isError(decryptedSnap)) {
				NSLog(@"Erreur de decryptage, string = %@", [NSString stringWithUTF8String:[result bytes]]);
			}
			else {
				NSString *url = [SMFileCollector saveSnap:snapid withData:decryptedSnap];
				SnapCall(callback, @{@"url": url}, nil);
			}
		}
	} asData:YES];
}
-(void)getStory:(NSString*)identifier withKey:(NSString*)keyString iv:(NSString*)ivString andCallback:(Callback)callback {
    NSString* saved = [self hasSnapSaved:identifier];
	if(saved) {
		SnapCall(callback, saved, nil);
		return;
	}
}
-(void)getUpdates:(Callback)callback {
	[self requestTo:@"/bq/updates" withCallback:^(id result) {
		if(isError(result)) {
			SnapCall(callback, AFError(result, YES), nil);
		}
		else {
			SnapCall(callback, result, nil);
		}
	}];
}
-(void)getStories:(Callback)callback {
	[self requestTo:@"/bq/stories" withCallback:^(id result) {
		if(isError(result)) {
			SnapCall(callback, AFError(result, YES), nil);
		}
		else {
			SnapCall(callback, result, nil);
		}
	}];
}
-(BOOL)use3D {
	return use3D;
}
-(void)switchToPhotoMode {
	SMCamView* camView = [[[NSApplication sharedApplication] delegate] performSelector:@selector(camView)];
	[camView cleanStart];
}

#pragma mark API Objective-C
-(void)hideSend {
	[self scriptTS:@"SnappyUI.hideSend();"];
}
-(id)script:(NSString*)command {
	return [_wso evaluateWebScript:command];
}


-(void)scriptTS:(NSString*)command {
	[_wso performSelectorOnMainThread:@selector(evaluateWebScript:) withObject:command waitUntilDone:NO];
}
-(void)setUse3D:(BOOL)use3d {
	use3D = use3d;
	NSString* cmd = [NSString stringWithFormat:@"SnappyUI.use3D(%@);", (use3D ? @"true" : @"false")];
	[self scriptTS:cmd];
}

@end
