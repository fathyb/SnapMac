//
//  SMJSClient.m
//  SnapMac
//
//  Created by Fathy B on 01/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMJSClient.h"
#import "SSKeychain.h"
#import "SnapMac.h"

@implementation SMJSClient



#pragma mark Outils


-(void)SMCallback:(NSString*)func withArgs:(NSArray*)args {
    NSMutableString *call = [NSMutableString stringWithFormat:@"window['%@'](", func];
    for(NSString* arg in args) {
        if([arg isEqualTo:args.firstObject])
            [call appendFormat:@"'%@', ", arg];
        if([arg isEqualTo:args.lastObject])
            [call appendFormat:@"'%@');", arg];
    }
    [self script:call];
}

-(NSString*)objectToJSON:(id)object {
    if(!object)
        return nil;
    NSError* error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
-(id)jsonToObject:(NSString*)data {
    NSError* error;
    id obj = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    return obj;
}
-(WebScriptObject*)wso {
    return [_webView windowScriptObject];
}

-(void)script:(NSString*)script {
    [[self wso] performSelectorOnMainThread:@selector(evaluateWebScript:) withObject:script waitUntilDone:NO];
}

#pragma Callbacks

-(void)foundThumbnail:(NSString*)thumbnailUrl forStory:(NSString*)storyId {
    [self script:[NSString stringWithFormat:@"addThumbForStory('%@', '%@');", thumbnailUrl, storyId]];
}
-(void)foundThumbnail:(NSString*)thumbnailUrl forSnap:(NSString*)snapId {
    [self script:[NSString stringWithFormat:@"addThumbForSnap('%@', '%@');", thumbnailUrl, snapId]];
}

#pragma mark WebKit
+(NSString*)webScriptNameForSelector:(SEL)sel {
    NSDictionary *selectors = @{
        @"connect:pass:": @"connect",
        @"errorWithTitle:informativeText:": @"error",
        @"getSnap:": @"getSnap",
        @"useAuthToken:withLogin:": @"useAuthToken",
        @"hasSnapSaved:": @"hasSnapSaved",
        @"showSnap:": @"showSnap",
        @"showNotification:": @"showNotification",
        @"getStoriesWithCallback:": @"getStoriesWithCallback",
        @"getSnap:withCallback:": @"getSnapWithCallback",
        @"getStory:withKey:iv:andCallback:": @"getStory"
    };
    for(NSString* selName in selectors) {
        if(NSSelectorFromString(selName) == sel) return selectors[selName];
    }
    return nil;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    return NO;
}


#pragma  mark Autres..
-(NSObject<NSApplicationDelegate>*)snapMacDelegate {
    return  [[NSApplication sharedApplication] delegate];
}
-(NSString*)defaultAuthToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"SMAuthToken"];
}
-(NSString*)defaultLogin {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"SMLogin"];
}
#pragma mark Fonctions JS


-(BOOL)doStoryAnim {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"SMStoryAnimation"] isEqualToString:@"true"];
}
-(void)showNotification:(NSString*)notif {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"SnapMac";
    notification.informativeText = notif;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
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
-(void)showSnap:(NSString*)snapid {
    NSString *url = [self hasSnapSaved:snapid forNative:YES];
    //if([url hasSuffix:@".mp4"])
      //  selector = NSSelectorFromString(@"showVideo:");
    id delegate = [self snapMacDelegate];
    if([delegate respondsToSelector:@selector(camView)]) {
        SMCamView *camView = [delegate performSelector:@selector(camView) withObject:nil];
        [camView showImageFile:url];
    }
}
-(NSString*)account {
    NSDictionary *account = [SSKeychain accountsForService:@"SnapMac"][0];
    NSError* error = nil;
    NSString *pass = [SSKeychain passwordForService:@"SnapMac" account:account[@"acct"] error:&error];
    if(error) {
        return [self objectToJSON:@{@"error":@YES, @"code": @([error code])}];
    }
    NSDictionary *jAccount = @{
        @"login": account[@"acct"],
        @"pass": pass
    };
    return [self objectToJSON:jAccount];
}
-(void)getStory:(NSString*)identifier withKey:(NSString*)keyString iv:(NSString*)ivString andCallback:(NSString*)callback {
    NSString* saved = [self hasSnapSaved:identifier];
    if(saved) {
        [self SMCallback:callback withArgs:@[identifier, saved]];
        //[self script:[NSString stringWithFormat:@"window['%@']('%@', '%@');", callback, identifier, saved]];
    }
    [_client getStory:identifier withKey:keyString iv:ivString andCallback:^(NSString* result) {
        [self SMCallback:callback withArgs:@[identifier, result]];
        //[self script:[NSString stringWithFormat:@"window['%@']('%@','%@');", callback, identifier, result]];
    }];
}
-(void)requestAndroidSync {
    _androidSync = [[SMAndroidSync alloc] initWithCallback:^(id object) {
        NSString *jsonRep;
        if([object isKindOfClass:[NSString class]]) {
            jsonRep = [self objectToJSON:@{
                @"error": object
            }];
        }
        else {
            jsonRep = [self objectToJSON:@{
                @"authToken": ((SMAndroidSync*)object).authToken,
                @"login": ((SMAndroidSync*)object).user
            }];
        }
        [[_webView windowScriptObject] evaluateWebScript:[NSString stringWithFormat:@"androidSync(%@);", jsonRep]];
    }];
}
-(void)getStoriesWithCallback:(NSString*)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) , ^{
        id stories = [_client stories];
        [[self wso] performSelectorOnMainThread:@selector(evaluateWebScript:) withObject:[NSString stringWithFormat:@"%@(%@);", callback, [self objectToJSON:stories]] waitUntilDone:NO];
        //[[self wso] evaluateWebScript:[NSString stringWithFormat:@"%@(%@);", callback, [self objectToJSON:stories]]];
    });
}
-(void)getSnap:(NSString*)snap withCallback:(NSString*)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString* snapData = [_client getSnap:snap];
        
        [[self wso] performSelectorOnMainThread:@selector(evaluateWebScript:) withObject:[NSString stringWithFormat:@"%@(%@, %@);", callback, snap, snapData] waitUntilDone:NO];
        //[[self wso] evaluateWebScript:[NSString stringWithFormat:@"%@(\"%@\");", callback, snapData]];
    });
}
-(void)sendPhoto {
    if([[self snapMacDelegate] respondsToSelector:@selector(camView)]) {
        NSView *camView = [[self snapMacDelegate] performSelector:@selector(camView) withObject:nil];
        if([camView respondsToSelector:@selector(mouseUp:)]) {
            NSImage *photo = [camView performSelector:@selector(currentImage) withObject:nil];
            NSString *friends = (NSString*)[[self wso] evaluateWebScript:@"getFriendsList();"];
            [_client sendMedia:photo toFriends:friends];
        }
    }
}
-(void)cancelSend {
    if([[self snapMacDelegate] respondsToSelector:@selector(camView)]) {
        SMCamView* camView = [[self snapMacDelegate] performSelector:@selector(camView) withObject:nil];
        [camView cleanStart];
    }
    [self script:@"SnappyUI.hideSend();"];
}
-(NSString*)getSnap:(NSString*)snap {
    return [_client getSnap:snap];
}
-(void)reqUpdate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* updates = [self objectToJSON:[_client updates]];
        [[self wso] performSelectorOnMainThread:@selector(evaluateWebScript:) withObject:[NSString stringWithFormat:@"SMUpdate(%@)", updates] waitUntilDone:NO];
    });
}
-(NSString*)getUpdates {
    id updates = [_client updates];
    return [self objectToJSON:updates];
}

-(BOOL)useAuthToken:(NSString*)authToken withLogin:(NSString*)login {
    _client = [SMClient clientWithAuthToken:authToken andLogin:login];
    _client.notifier = self;
    return YES;
}

-(NSString*)listBackups {
    NSFileManager *fManager = [NSFileManager defaultManager];
    NSArray *backups = [fManager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/MobileSync/Backup", NSHomeDirectory()] error:nil];
    NSMutableDictionary *backupList = [NSMutableDictionary new];
    BOOL fExist;
    for(NSString* backup in backups) {
        NSDictionary *infoPlist = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Application Support/MobileSync/Backup/%@/Info.plist", NSHomeDirectory(), backup]];
        fExist = [fManager fileExistsAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/MobileSync/Backup/%@/6fecfd24755d604fd70614fce8f26b8def9904fa", NSHomeDirectory(), backup] isDirectory:nil];
        if(!fExist) continue;
        NSArray *snapPlist = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Application Support/MobileSync/Backup/%@/6fecfd24755d604fd70614fce8f26b8def9904fa", NSHomeDirectory(), backup]][@"$objects"];
        backupList[[NSString stringWithFormat:@"%@ (%@ - %@)", infoPlist[@"Device Name"], infoPlist[@"Product Name"], infoPlist[@"Product Version"]]] = @[snapPlist[3], snapPlist[4]];
    }
    return [self objectToJSON:backupList];
}
-(void)errorWithTitle:(NSString*)title informativeText:(NSString*)informativeText {
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:informativeText];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[[NSApplication sharedApplication] mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}



-(BOOL)connect:(NSString*)login pass:(NSString*)pass {
    _client = [SMClient clientWithLogin:login andPassword:pass];
    _client.notifier = self;
    BOOL connected = [_client connect];
    if(connected == YES) {
        [SSKeychain setPassword:pass forService:@"SnapMac" account:login];
    }
    return connected;
}
@end
