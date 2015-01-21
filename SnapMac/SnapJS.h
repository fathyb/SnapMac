//
//  SnapJS.h
//  SnapMac
//
//  Created by Fathy Boundjadj  on 11/08/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "SnapBack.h"
#import "SnappyNotification.h"
#import "SMWebUI.h"
#import "SMAndroidSync.h"


enum {
    SnappyMethodGET  = 0,
    SnappyMethodPOST = 1
};
typedef NSInteger SnappyMethod;


typedef NS_ENUM(NSUInteger, SnappyError) {
    SnappyErrorUnknowError     = 0,
    SnappyErrorBadPassword     = 1,
    SnappyErrorBadUsername     = 2,
    SnappyErrorNoConnection    = 3,
    SnappyErrorFailedToConnect = 4,
    SnappyErrorNotAuthorized   = 5
};


#define SNAPCHAT_VERSION "7.1.0.10"

@interface SnapJS : NSObject <NSTextFieldDelegate>

-(void)script:(NSString*)command;

@property (nonatomic) NSString* authToken;
@property (nonatomic) NSString* username;
@property (nonatomic, weak) SMWebUI* webView;
@property (nonatomic) NSOperationQueue* opQueue;
@property (nonatomic) SMAndroidSync* androSync;
@property (nonatomic) BOOL logged;
@property (nonatomic) BOOL use3D;
@property (nonatomic) BOOL useParallax;
@property (nonatomic) BOOL hideFeedPics;
@property (nonatomic) BOOL darkTheme;

@end
