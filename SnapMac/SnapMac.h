//
//  SMAppDelegate.h
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "SMWebUI.h"
#import "SMSettings.h"
#import "SMCamView.h"
#import "SMImage.h"
#import "SMHTTPServer.h"
#import "SMPhotoButton.h"
#import "About.h"

@interface SnapMac : NSObject <NSApplicationDelegate, NSSplitViewDelegate, NSUserNotificationCenterDelegate, NSWindowDelegate> {
    __weak NSPopUpButton *effectList;
}


@property (weak) IBOutlet NSLayoutConstraint *cameraPosition;
@property (nonatomic)       NSView* mainButtonView;
@property (nonatomic)       AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic)       AVCaptureSession* session;
@property (nonatomic)       NSDictionary* effects;
@property (nonatomic)       SMWebUI* webUI;
@property (nonatomic)       SMSettings* settingsView;
@property (nonatomic)       CALayer* progressLayer;
@property (nonatomic)       SMHTTPServer* server;
@property (weak) IBOutlet   SMWebUI* webView;
@property (weak) IBOutlet   SMCamView* camView;
@property (weak) IBOutlet   NSPopUpButton* effectList;
@property (weak) IBOutlet   SMPhotoButton* photoButton;
@property (assign) IBOutlet NSWindow* window;
@property (weak) IBOutlet NSLayoutConstraint *photoToolsYPos;
@property (weak) IBOutlet NSView *photoToolsView;
@property (nonatomic) About* about;

@end
