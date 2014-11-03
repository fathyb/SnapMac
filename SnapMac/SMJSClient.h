//
//  SMJSClient.h
//  SnapMac
//
//  Created by Fathy B on 01/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "SMClient.h"
#import "SMAndroidSync.h"
#import <AVFoundation/AVFoundation.h>
#import "SMCamView.h"

@interface SMJSClient : NSObject

@property SMAndroidSync* androidSync;
@property SMClient* client;
@property WebView* webView;

-(void)foundThumbnail:(NSString*)thumbnailUrl forSnap:(NSString*)snapId;
-(void)foundThumbnail:(NSString*)thumbnailUrl forStory:(NSString*)storyId;
-(NSString*)hasSnapSaved:(NSString*)snapid forNative:(BOOL)native;

@end
