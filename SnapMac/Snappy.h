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
#import "Settings.h"
#import "SMCamView.h"
#import "SMImage.h"
#import "SMPhotoButton.h"
#import "About.h"
#import "SMWindow.h"
#import "SMClearFeedWindow.h"

@interface Snappy : NSObject <NSApplicationDelegate, NSSplitViewDelegate, NSUserNotificationCenterDelegate, NSWindowDelegate> {
    __weak NSPopUpButton *effectList;
}


@property (weak) IBOutlet NSSearchField *searchField;
@property (nonatomic)       NSView* mainButtonView;
@property (nonatomic)       AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic)       AVCaptureSession* session;
@property (nonatomic)       NSDictionary* effects;
@property (nonatomic)       Settings* settingsView;
@property (nonatomic)       CALayer* progressLayer;
@property (nonatomic)       SMClearFeedWindow* clearFeedWindow;
@property (weak) IBOutlet   SMWebUI* webView;
@property (weak) IBOutlet   SMCamView* camView;
@property (weak) IBOutlet   NSPopUpButton* effectList;
@property (weak) IBOutlet   SMPhotoButton* photoButton;
@property (assign) IBOutlet SMWindow* window;
@property (weak) IBOutlet NSLayoutConstraint *camPosConstraint;
@property (nonatomic) About* about;

@end
