//
//  SMAndroidSync.m
//  SnapMac
//
//  Created by Fathy B on 07/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMAndroidSync.h"

@implementation SMAndroidSync

-(SMAndroidSync*)initWithCallback:(SMCallback)callback {
    if(self = [super init]) {
        _callback = callback;
        [self performSelectorInBackground:@selector(doInit) withObject:nil];
    }
    return self;
}
-(void)doInit {
    NSLog(@"SnapMac AndroidSync launching...");
    NSString *adbPath = [[NSBundle mainBundle] pathForResource:@"adb" ofType:@""];
    NSTask *startServer = [NSTask launchedTaskWithLaunchPath:adbPath arguments:@[@"start-server"]];
    [startServer waitUntilExit];
    
    NSTask *task = [NSTask new];
    task.launchPath = adbPath;
    task.arguments = @[@"shell", @"su -c \"cat /data/data/com.snapchat.android/shared_prefs/com.snapchat.android_preferences.xml\""];
    _current = @"";
    _authToken = nil;
    _user = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        task.standardError = outputPipe;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readCompleted:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[outputPipe fileHandleForReading]];
        [[outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
        [task launch];
        
    });
}
-(void)readCompleted:(NSNotification *)notification {
    id data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if([data isKindOfClass:[NSData class]]) {
        NSString *adbOutput = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if([adbOutput rangeOfString:@"device not found"].location != NSNotFound) {
            _callback(@"Pas d'appareil");
            return;
        }
        if([adbOutput rangeOfString:@"denied"].location != NSNotFound) {
            _callback(@"Pas de root");
            return;
        }
        if([adbOutput rangeOfString:@"unauthorized"].location != NSNotFound) {
            _callback(@"Non autorisé");
            return;
        }
        
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        parser.delegate = self;
        BOOL parsed = [parser parse];
        if(_callback) {
            if(parsed) _callback(self);
            else {
                _callback(@"Erreur du traitement des données Snapchat");
                NSLog(@"adbOutput = %@", adbOutput);
            }
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
    _current = @"";
    if ([elementName isEqualToString:@"string"])
        _current = attributeDict[@"name"];
}
-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if(!string)
        return;
    else if([_current isEqualToString:@"auth_token"] && !_authToken)
        _authToken = string;
    else if(([_current isEqualToString:@"currentUser"] || [_current isEqualToString:@"display_name"]) && !_user)
        _user = string;
    else
        return;
    NSLog(@"Found %@ = %@", _current, string);
}

@end
