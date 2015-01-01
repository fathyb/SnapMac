//
//  SMCamView.h
//  SnapMac
//
//  Created by Fathy B on 14/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "SMPhotoButton.h"
#import "SMQuitMediaButton.h"
#import "Settings.h"

@class SMPaintingLayer;
@class SMLine;

@interface SMCamView : NSView

@property (nonatomic) AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) NSMutableDictionary *twoFingerTouches;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) NSImage *currentImage;
@property (nonatomic) BOOL showCancelBtn;
@property (nonatomic) BOOL showPhotoBtn;
@property (nonatomic) BOOL showFilterList;
@property (nonatomic) BOOL showRefreshBtn;
@property (nonatomic) BOOL showFlashBtn;
@property (nonatomic) BOOL showDrawBtn;
@property (nonatomic) BOOL showColorPickerBtn;
@property (nonatomic) BOOL showUndoDrawBtn;
@property (nonatomic) BOOL isDrawingEnabled;
@property (nonatomic) BOOL down;
@property (nonatomic) NSLayoutConstraint *positionLeft;
@property (nonatomic) NSBezierPath *path;
@property (nonatomic) SMLine *currentLine;
@property (nonatomic) SMPaintingLayer *paintingLayer;
@property (nonatomic) NSColor *drawingColor;

-(void)setFilter:(CIFilter*)filter;
-(void)cleanStart;
-(void)show;
-(void)hide;
-(void)resetSubviews;
-(void)showImageFile:(NSString*)path;
-(void)showImage:(NSImage*)image;
-(void)showImage:(NSImage*)image withTools:(BOOL)useOpts;
-(void)photo:(SMCallback)callback;
@end
