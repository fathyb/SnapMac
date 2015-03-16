//
//  SMCamView.m
//  SnapMac
//
//  Created by Fathy B on 14/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMCamView.h"
#import "SMImage.h"
#import "SMLoadingView.h"
#import "SMPhotoButton.h"
#import "SMRefreshBouton.h"
#import "SMDrawButton.h"
#import "SMLine.h"
#import "SMPaintingLayer.h"
#import "SMDrawButton.h"
#import "SMUndoDrawButton.h"
#import "SMColorPickerButton.h"
#import "SMFlashButton.h"
#import "SMTimerLayer.h"

#define kSwipeMinimumLength 0.15

@implementation SMCamView

@synthesize showCancelBtn,
            showPhotoBtn,
            showRefreshBtn,
            showDrawBtn,
            showFilterList,
            showFlashBtn,
            showUndoDrawBtn,
            showColorPickerBtn,
            previewLayer,
            session,
            twoFingerTouches,
            stillImageOutput,
            currentImage;


float currentSum;
float scrollDeltaY;
float scrollDeltaX;
BOOL downed;
BOOL isHandlingEvent;

#pragma mark Support touchpad multitouch
-(BOOL)acceptsTouchEvents {
    return YES;
}
-(BOOL)wantsRestingTouches {
    return YES;
}
-(BOOL)acceptsFirstResponder {
    return YES;
}
-(BOOL)recognizeTwoFingerGestures {
    NSUserDefaults* defaults = NSUserDefaults.standardUserDefaults;
    return [defaults boolForKey:@"AppleEnableSwipeNavigateWithScrolls"];
}

-(void)scrollWheel:(NSEvent*)event {
    if (twoFingerTouches)
        return;
    if(!NSEvent.isSwipeTrackingFromScrollEventsEnabled) {
        [super scrollWheel:event];
        return;
    }
    if(event.phase == NSEventPhaseBegan) {
        currentSum = 0;
        scrollDeltaX = 0;
        scrollDeltaY = 0;
        isHandlingEvent = YES;
    }
    switch(event.phase) {
        case NSEventPhaseChanged:
            if(!isHandlingEvent) {
                if(currentSum != 0)
                    currentSum = 0;
            }
            else {
                scrollDeltaX += event.scrollingDeltaX;
                scrollDeltaY += event.scrollingDeltaY;
            
                float absoluteSumX = fabsf(scrollDeltaX);
                float absoluteSumY = fabsf(scrollDeltaY);
                if((absoluteSumX < absoluteSumY && currentSum == 0)) {
                    isHandlingEvent = NO;
                    if(currentSum != 0)
                        currentSum = 0;
                }
                else {
                    CGFloat flippedDeltaX = scrollDeltaX * -1;
                    if(flippedDeltaX == 0) {
                        if(currentSum != 0)
                            currentSum = 0;
                    }
                    else {
                        currentSum = flippedDeltaX/1000;
                        return;
                    }
                }
            }
            break;
        case NSEventPhaseMayBegin:
        case NSEventPhaseCancelled:
            isHandlingEvent = NO;
            if(currentSum != 0)
                currentSum = 0;
            break;
        default:
            break;
        case NSEventPhaseEnded:
            if(fabsf(currentSum) < kSwipeMinimumLength || !currentSum)
                return;
            
            id delegate = NSApplication.sharedApplication.delegate;
            SEL selector = NSSelectorFromString(currentSum > 0 ? @"prevFilter" : @"nextFilter");
            if([delegate respondsToSelector:selector])
                [delegate performSelectorInBackground:selector withObject:nil];
            
            isHandlingEvent = NO;
            if(currentSum != 0)
                currentSum = 0;
            
            break;
    }
    [super scrollWheel:event];
}

-(void)swipeWithEvent:(NSEvent*)event {
    CGFloat x = event.deltaX;
    if(!x)
        return;
    id delegate = NSApplication.sharedApplication.delegate;
    SEL selector = NSSelectorFromString(x < 0 ? @"prevFilter" : @"nextFilter");
    if([delegate respondsToSelector:selector])
        [delegate performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
}

#pragma mark NSView methods
-(void)mouseDown:(NSEvent*)theEvent {
    if(!self.isDrawingEnabled)
        return [super mouseDown:theEvent];
    
    NSPoint loc = theEvent.locationInWindow;
    loc.x -= self.frame.origin.x;
    loc.y -= self.frame.origin.y;
    
    SMLine *line = SMLine.new;
    line.color   = CGColorCreateCopy(self.drawingColor.CGColor);
    line.begin   = loc;
    line.end     = loc;
    
    self.currentLine = line;
}
- (void)mouseDragged:(NSEvent*)theEvent {
    if(!self.isDrawingEnabled || !self.currentLine)
        return [super mouseDragged:theEvent];
    
    SMPaintingLayer *layer = self.paintingLayer;
    
    if(!layer)
        return;
    
    NSPoint loc = theEvent.locationInWindow;
    loc.x -= self.frame.origin.x;
    loc.y -= self.frame.origin.y;
    
    self.currentLine.end = loc;
    [layer.lines addObject:self.currentLine];
    
    SMLine *line = SMLine.new;
    line.color   = CGColorCreateCopy(self.drawingColor.CGColor);
    line.begin   = loc;
    line.end     = loc;
    
    self.currentLine = line;
    
    [layer setNeedsDisplay];
}
-(void)drawRect:(NSRect)dirtyRect {
    [NSColor.redColor set];
    
    [self.path stroke];
}

-(void)awakeFromNib {
    
    NSDictionary* notifications = @{
        NSWindowDidResizeNotification: @"screenResize:",
                  @"SnappyShowCamera": @"showCamera:",
                   @"SnappyShowMedia": @"showMedia:",
                @"SnappyRefreshVideo": @"refreshVideo:",
                   @"SnappyNeedPhoto": @"needPhoto:",
              @"IGotCamPosConstraint": @"setPosConstraint:",
                   @"SnappyTakePhoto": @"takePhoto:",
               @"SnappyToggleDrawing": @"toggleDrawing:",
          @"SnappyChangeDrawingColor": @"changeDrawingColor:",
               @"SnappyUndoDirtyDraw": @"undoDraw:"
    };
    
    NSNotificationCenter* center = NSNotificationCenter.defaultCenter;
    
    for(NSString *k in notifications.allKeys)
        [center addObserver:self
                   selector:NSSelectorFromString(notifications[k])
                       name:k
                     object:nil];
    
    [self showLoading];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
    
        SEL useCIFilters = NSSelectorFromString(@"setLayerUsesCoreImageFilters:");
        if([self respondsToSelector:useCIFilters])
            [self performSelectorInBackground:useCIFilters withObject:@YES];
    
         session = [AVCaptureSession new];
        [session beginConfiguration];
         session.sessionPreset = AVCaptureSessionPresetPhoto;
        [session commitConfiguration];
    
        for(AVCaptureDevice *device in [AVCaptureDevice devices]) {
            if([device hasMediaType:AVMediaTypeVideo] || [device hasMediaType:AVMediaTypeMuxed]) {
                AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                if (error) {
                    NSLog(@"deviceInputWithDevice failed with error %@", error.localizedDescription);
                }
                if([session canAddInput:input])
                    [session addInput:input];
                break;
            }
        }
    
        stillImageOutput = AVCaptureStillImageOutput.new;
        if([session canAddOutput:stillImageOutput])
            [session addOutput:stillImageOutput];
    
        previewLayer               = [AVCaptureVideoPreviewLayer.alloc initWithSession:self->session];
        previewLayer.frame         = self.bounds;
        previewLayer.opacity       = 1.f;
        previewLayer.videoGravity  = AVLayerVideoGravityResizeAspectFill;
        previewLayer.masksToBounds = YES;
        
        previewLayer.connection.automaticallyAdjustsVideoMirroring = NO;
        previewLayer.connection.videoMirrored                      = YES;
        
        [self cleanStart];
        [self hideLoading];
    });
}

#pragma mark Utils
NSRect getPerfectRect(NSSize imageSize, NSSize layerSize) {
    
    float width		 = imageSize.width;
    float height	 = imageSize.height;
    
    float newWidth  = layerSize.width;
    float newHeight = layerSize.height;
    
    float scaleFactor  = 0.0;
    float scaledWidth  = newWidth;
    float scaledHeight = newHeight;
    
    NSPoint thumbnailPoint = NSZeroPoint;
    
    if(!NSEqualSizes(imageSize, layerSize)) {
        float widthFactor  = newWidth / width;
        float heightFactor = newHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width  * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if (widthFactor < heightFactor)
            thumbnailPoint.y = (newHeight - scaledHeight) * 0.5;
        
        else if (widthFactor > heightFactor)
            thumbnailPoint.x = (newWidth - scaledWidth) * 0.5;
    }
    
    CGFloat x = layerSize.width/2 - scaledWidth/2;
    CGFloat y = layerSize.height/2 - scaledHeight/2;

    return NSMakeRect(x, y, scaledWidth, scaledHeight);
    
}
#pragma mark Notification Center
-(void)undoDraw:(NSNotification*)notif {
    if(!self.isDrawingEnabled)
        return;
    
    [self.paintingLayer.lines removeLastObject];
    [self.paintingLayer setNeedsDisplay];
}
-(void)screenResize:(NSNotification*)notif {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    if(_positionLeft.constant != 0)
            _positionLeft.constant = -self.bounds.size.width;
    
    if(!self.layer)
        goto quit;
    
    if(self.paintingLayer)
        [self.paintingLayer resizeTo:self.layer.frame.size];
    
    if([self.layer isKindOfClass:[AVPlayerLayer class]]) {
        CALayer *playerLayer = self.layer;
        if(playerLayer.sublayers.count > 1) {
            CALayer *overlayLayer = playerLayer.sublayers[1];
            NSImage *overlayImage = overlayLayer.contents;
            NSSize imageSize = overlayImage.size;
            NSSize layerSize = playerLayer.frame.size;
        
            NSRect rect = getPerfectRect(imageSize, layerSize);
        
            overlayLayer.frame = rect;
        }
    }
    for(CALayer *layer in self.layer.sublayers) {
        if([layer isKindOfClass:SMTimerLayer.class]) {
            NSSize layerSize = self.layer.bounds.size;
           layer.frame = NSMakeRect(layerSize.width - (20 + 50), layerSize.height - (20 + 50), 50, 50);
            [layer setNeedsDisplay];
        }
    }
    
    goto quit;
quit:
    
    [CATransaction commit];
}
-(void)refreshVideo:(NSNotification*)notif {
    if([self.layer isKindOfClass:AVPlayerLayer.class]) {
        AVPlayerLayer *playerLayer = (AVPlayerLayer*)self.layer;
        AVPlayer *player = playerLayer.player;
        
        [player seekToTime:CMTimeMake(0, 1)];
        [player play];
    }
}
-(void)toggleDrawing:(NSNotification*)notif {
    BOOL value = [notif.object boolValue];
    
    self.isDrawingEnabled = value;
    if(value)
        [self showDrawingLayer];
    else
        [self hideDrawingLayer];
}
-(void)changeDrawingColor:(NSNotification*)notif {
    self.drawingColor = notif.object;
}
-(void)needPhoto:(NSNotification*)notif {
    NSImage *image = self.layer.contents;
    if(self.paintingLayer)
        [self.paintingLayer drawInImage:image];
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"SnappyIGotPhoto"
                                                      object:image];
}
-(void)setPosConstraint:(NSNotification*)notif {
    self.positionLeft = notif.object;
}
-(void)showCamera:(NSNotification*)notif {
    if(!notif)
        return;
    
    NSNumber* obj = notif.object;
    if(obj.boolValue)
        [self show];
    else
        [self hide];
}

-(void)takePhoto:(NSNotification*)notif {
    [self photo:^(NSImage* image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showImage:image withTools:YES];
        });
    }];
}


-(void)showAndUseCamera:(BOOL)showCamera {
    _positionLeft.animator.constant = 0;
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"ShowingCamera"
                                                            object:self];
    
    if(showCamera)
        [self cleanStart];
}
-(void)show {
    [self showAndUseCamera:YES];
}
-(void)hide {
    _positionLeft.animator.constant = -self.bounds.size.width;
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"ClosingCamera"
                                                            object:self];
    [self cleanStop];
}
#pragma mark Getters

-(NSView*)photoTools {
    return (NSView*)(self.superview.subviews[1]);
}
-(id)photoToolsSubview:(Class)class {
    for(NSView* subview in self.photoTools.subviews) {
        if([subview isKindOfClass:class]) return subview;
    }
    return nil;
}
-(NSPopUpButton*)filterList {
    return [self photoToolsSubview:NSPopUpButton.class];
}
-(SMPhotoButton*)photoBtn {
    return [self photoToolsSubview:SMPhotoButton.class];
}
-(SMRefreshBouton*)refreshBtn {
    return [self photoToolsSubview:SMRefreshBouton.class];
}
-(SMDrawButton*)drawBtn {
    return [self photoToolsSubview:SMDrawButton.class];
}
-(SMColorPickerButton*)colorPickerBtn {
    return [self photoToolsSubview:SMColorPickerButton.class];
}
-(SMColorPickerButton*)undoDrawBtn {
    return [self photoToolsSubview:SMUndoDrawButton.class];
}
-(SMLoadingView*)loadingView {
    return [self photoToolsSubview:SMLoadingView.class];
}
-(NSProgressIndicator*)loadingView_spin {
    return self.loadingView.subviews[1];
}
-(SMQuitMediaButton*)cancelBtn {
    return self.photoTools.subviews[2];
}
-(SMFlashButton*)flashBtn {
    return [self photoToolsSubview:SMFlashButton.class];
}

#pragma mark Setters

-(void)setShowFilterList:(BOOL)val {
    showFilterList = val;
    self.filterList.animator.alphaValue = val;
}
-(void)setShowPhotoBtn:(BOOL)val {
    showPhotoBtn = val;
    if(val)
        [self.photoBtn show];
    else
        [self.photoBtn hide];
}
-(void)setShowCancelBtn:(BOOL)val {
    showCancelBtn = val;
    if(val)
        [self.cancelBtn show];
    else
        [self.cancelBtn hide];
}
-(void)setShowFlashBtn:(BOOL)val {
    showFlashBtn = val;
    if(val)
        [self.flashBtn show];
    else
        [self.flashBtn hide];
}

-(void)setShowRefreshBtn:(BOOL)val {
    showRefreshBtn = val;
    if(val)
        [self.refreshBtn show];
    else
        [self.refreshBtn hide];
}
-(void)setShowDrawBtn:(BOOL)val {
    showDrawBtn = val;
    if(val)
        [self.drawBtn show];
    else
        [self.drawBtn hide];
}
-(void)setShowColorPickerBtn:(BOOL)val {
    showColorPickerBtn = val;
    if(val)
        [self.colorPickerBtn show];
    else
        [self.colorPickerBtn hide];
}
-(void)setShowUndoDrawBtn:(BOOL)val {
    showUndoDrawBtn = val;
    if(val)
        [self.undoDrawBtn show];
    else
        [self.undoDrawBtn hide];
}
#pragma mark UI API

-(void)photo:(SMCallback)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        Settings *settings = Settings.sharedInstance;
        BOOL      useFlash = [[settings objectForKey:@"SMUseFlash"] boolValue];
        if(useFlash)
            [self flashScreen:YES];
        
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:[stillImageOutput connectionWithMediaType:AVMediaTypeVideo]
                                                      completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
            if(useFlash)
                [self flashScreen:NO];
            
            if(!error && imageSampleBuffer) {
                [session performSelectorOnMainThread:@selector(stopRunning)
                                          withObject:nil
                                       waitUntilDone:NO];
                
                NSData        *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                NSImage       *oldImage = [NSImage.alloc initWithData:jpegData];
                
                CGFloat     imageHeight = oldImage.size.height;
                NSSize        imageSize = NSMakeSize(imageHeight/1.5, imageHeight);
                NSRect          newRect = NSMakeRect((oldImage.size.width-imageSize.width)/2, (oldImage.size.height-imageSize.height)/2,
                                                    imageSize.width, imageSize.height);
                
                CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)oldImage.TIFFRepresentation, nil);
                CGImageRef    nImageRef = CGImageSourceCreateImageAtIndex(source, 0, nil),
                               imageRef = CGImageCreateWithImageInRect(nImageRef, newRect);
                
                NSImage       *newImage = [NSImage.alloc initWithCGImage:imageRef
                                                                    size:newRect.size];
                NSArray        *filters = previewLayer.filters;
                
                if(source)
                    CFRelease(source);
                if(nImageRef)
                    CFRelease(nImageRef);
                if(imageRef)
                    CFRelease(imageRef);
                
                [newImage setFilter:(filters.count > 0 ? filters[0] : nil)];
                [newImage flipImage];
                
                callback(newImage);
            }
            else {
                callback(error);
            }
        }];
    });
    
}
-(void)flashScreen:(BOOL)flash {
    CGDisplayFadeReservationToken fadeToken;
    
    CGError           error = CGAcquireDisplayFadeReservation(.5, &fadeToken);
    NSColor*     flashColor = [NSColor colorWithCalibratedRed:255
                                                        green:255
                                                         blue:255
                                                        alpha:1];
    
    if (error != kCGErrorSuccess)
        return;
    
    CGDisplayFade(fadeToken,
                  .25,
                  flash ? kCGDisplayBlendNormal : kCGDisplayBlendSolidColor,
                  flash ? kCGDisplayBlendSolidColor : kCGDisplayBlendNormal,
                  flashColor.redComponent,
                  flashColor.greenComponent,
                  flashColor.blueComponent,
                  flash);
    
    if(flash)
        usleep(250000);
    
}

-(void)showLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loadingView.hidden = NO;
        [self.loadingView_spin startAnimation:nil];
    });
}
-(void)hideLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loadingView.hidden = YES;
        [self.loadingView_spin stopAnimation:nil];
    });
}

-(void)setFilter:(CIFilter*)filter {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoading];
        
        if(session.isRunning)
            self.layer.filters = filter ? @[filter] : nil;
        
        [self hideLoading];
    });
}

-(void)cleanStart {
    if(self.layer.contents)
        self.layer.contents = nil;
    
    currentImage = nil;
    self.layer   = previewLayer;
    
    self.showCancelBtn      =
    self.showColorPickerBtn =
    self.showDrawBtn        =
    self.showUndoDrawBtn    =
    self.showRefreshBtn     = NO;
    
    self.showPhotoBtn   =
    self.showFilterList =
    self.showFlashBtn   = YES;
    
    if(!session.isRunning) {
        [self showLoading];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{//return;
            [session performSelectorOnMainThread:@selector(startRunning)
                                      withObject:nil
                                   waitUntilDone:YES];
            sleep(2);
            [self hideLoading];
        });
    }
    
    [self resetSubviews];
}
-(void)cleanStop {
    self.layer = CALayer.new;
    if(session.isRunning)
            [session stopRunning];
    [self hideLoading];
    [self resetSubviews];
}

-(void)showDrawingLayer {
    SMPaintingLayer *layer = SMPaintingLayer.new;
    layer.frame = self.layer.bounds;
    [self.layer addSublayer:layer];
    
    self.showColorPickerBtn =
    self.showUndoDrawBtn    =
    self.isDrawingEnabled   = YES;
    self.paintingLayer      = layer;
}
-(void)hideDrawingLayer {
    self.layer.sublayers    = @[];
    self.paintingLayer      = nil;
    self.showColorPickerBtn =
    self.showUndoDrawBtn    =
    self.isDrawingEnabled   = NO;
}

-(void)resetSubviews {
    self.photoTools.layer = CALayer.new;
}
-(void)showImageFile:(NSString*)path {
    NSImage *sourceImage = [NSImage.alloc initWithContentsOfFile:path];
    [self showImage:sourceImage];
}
-(void)showImage:(NSImage*)image {
    [self showImage:image withTools:NO];
}
-(void)showImage:(NSImage*)image withTools:(BOOL)useOpts {
    [self cleanStop];
    
    self.showDrawBtn        = useOpts;
    self.showCancelBtn      = YES;
    self.showRefreshBtn     =
    self.showUndoDrawBtn    =
    self.showColorPickerBtn =
    self.showPhotoBtn       =
    self.showFilterList     =
    self.showFlashBtn       = NO;
    
    self.layer.contents = [image imageResizedToSize:self.bounds.size];
}

-(void)showVideo:(NSDictionary*)urls {
    NSString *path = urls[@"filePath"];
    
    AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:path]];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.layer.bounds;
    
    self.layer = playerLayer;
    
    NSString *overlay = urls[@"overlay"];
    
    if(overlay.length) {
        CALayer *overlayLayer = CALayer.new;
        NSImage *overlayImage = [NSImage.alloc initWithContentsOfFile:overlay];
        overlayLayer.contents = overlayImage;
        
        NSSize imageSize = overlayImage.size;
        NSSize layerSize = playerLayer.frame.size;
        
        overlayLayer.frame = getPerfectRect(imageSize, layerSize);
        
        [playerLayer addSublayer:overlayLayer];
    }
    
    [player play];
    
    
}
-(void)showMedia:(NSNotification*)notif {
    if(!notif)
        return;
    
    NSDictionary *urls = notif.object;
    
    if(!urls)
        return;
    
    self.showRefreshBtn = YES;
    NSString* path = urls[@"filePath"];
    
    if(_positionLeft.animator.constant != 0)
        [self showAndUseCamera:NO];
    
    [self cleanStop];
    
    self.showCancelBtn  = YES;
    
    self.showRefreshBtn =
    self.showPhotoBtn   =
    self.showFilterList =
    self.showFlashBtn   = NO;
    
    if([path hasSuffix:@"jpg"] || [path hasSuffix:@"jpeg"] || [path hasSuffix:@"png"])
        [self showImageFile:path];
    else if([path hasSuffix:@"mp4"] || [path hasSuffix:@"3gpp"])
        [self showVideo:urls];
    
    NSSize size = self.layer.bounds.size;
    self.timerLayer = SMTimerLayer.new;
    self.timerLayer.frame = NSMakeRect(size.width - (20 + 50), size.height - (20 + 50), 50, 50);
    
    [self.layer addSublayer:self.timerLayer];
    [self.timerLayer launchWithTimeout:[urls[@"timeout"] integerValue]];
    
    [self resetSubviews];
}


+(BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    return NO;
}

@end
