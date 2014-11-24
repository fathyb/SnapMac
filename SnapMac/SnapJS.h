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

enum {
    SnappyErrorUnknowError = 0,
    SnappyErrorBadPassword = 1,
    SnappyErrorBadUsername = 2,
    SnappyErrorNoConnection = 3,
    SnappyErrorFailedToConnect = 4,
    SnappyErrorNotAuthorized = 5
};
typedef NSInteger SnappyError;

#define SNAPCHAT_VERSION "7.1.0.10"

@interface SnapJS : NSObject

-(id)script:(NSString*)command;
-(void)scriptTS:(NSString*)command;
-(void)setUse3D:(BOOL)use3D;

@property (nonatomic) NSString* authToken;
@property (nonatomic) NSString* username;
@property (nonatomic) WebView* webView;
@property (nonatomic) BOOL logged;

@end
