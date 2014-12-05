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
#import "SMPhotoToolsView.h"

#define kSwipeMinimumLength 0.15

@implementation SMCamView

@synthesize showCancelBtn,
            showPhotoBtn,
            showFilterList,
            showPhotoTools,
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
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"AppleEnableSwipeNavigateWithScrolls"];
}

-(void)scrollWheel:(NSEvent *)event {
    if (twoFingerTouches) return;
    if(![NSEvent isSwipeTrackingFromScrollEventsEnabled]) {
        [super scrollWheel:event];
        return;
    }
    if([event phase] == NSEventPhaseBegan) {
        currentSum = 0;
        scrollDeltaX = 0;
        scrollDeltaY = 0;
        isHandlingEvent = YES;
    }
    else if([event phase] == NSEventPhaseChanged) {
        if(!isHandlingEvent) {
            if(currentSum != 0)
                currentSum = 0;
        }
        else {
            scrollDeltaX += [event scrollingDeltaX];
            scrollDeltaY += [event scrollingDeltaY];
            
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
    }
    else if([event phase] == NSEventPhaseEnded) {
        
        float absoluteSum = fabsf(currentSum);
        
        if (absoluteSum < kSwipeMinimumLength) return;
        
        if(!currentSum) return;
        id delegate = [[NSApplication sharedApplication] delegate];
        SEL selector = NSSelectorFromString(currentSum > 0 ? @"prevFilter" : @"nextFilter");
        if([delegate respondsToSelector:selector]) {
            [delegate performSelectorInBackground:selector withObject:nil];
        }
        isHandlingEvent = NO;
        if(currentSum != 0)
            currentSum = 0;
    }
    else if([event phase] == NSEventPhaseMayBegin || [event phase] == NSEventPhaseCancelled) {
        isHandlingEvent = NO;
        if(currentSum != 0)
            currentSum = 0;
    }
    [super scrollWheel:event];
}

-(void)swipeWithEvent:(NSEvent*)event {
    CGFloat x = [event deltaX];
    if(!x) return;
    id delegate = [[NSApplication sharedApplication] delegate];
    SEL selector = NSSelectorFromString(x < 0 ? @"prevFilter" : @"nextFilter");
    if([delegate respondsToSelector:selector]) {
        [delegate performSelectorOnMainThread:selector withObject:nil waitUntilDone:NO];
    }
}
-(void)photo:(SMCallback)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        SMSettings *settings = [SMSettings sharedInstance];
        if([[settings objectForKey:@"SMUseFlash"] boolValue])
            [self flashScreen:YES];
        
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
            if([[settings objectForKey:@"SMUseFlash"] boolValue])
                [self flashScreen:NO];
            
            if(!error && imageSampleBuffer) {
                [session performSelectorOnMainThread:@selector(stopRunning) withObject:nil waitUntilDone:NO];
                
                NSData        *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                NSImage       *oldImage = [[NSImage alloc] initWithData:jpegData];
                NSRect          newRect = NSMakeRect(400, 0, 480, 720);
                CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[oldImage TIFFRepresentation], nil);
                CGImageRef    nImageRef = CGImageSourceCreateImageAtIndex(source, 0, nil);
                CGImageRef     imageRef = CGImageCreateWithImageInRect(nImageRef, newRect);
                NSImage       *newImage = [[NSImage alloc] initWithCGImage:imageRef size:newRect.size];
                NSArray        *filters = previewLayer.filters;
                
                CFRelease(source);
                CFRelease(nImageRef);
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
    
    NSColor*     flashColor = [NSColor colorWithCalibratedRed:255
                                                        green:255
                                                         blue:255
                                                        alpha:1];
    NSTimeInterval duration = .25;
    CGError        error    = CGAcquireDisplayFadeReservation(duration * 2, &fadeToken);
    
    if (error != kCGErrorSuccess)
        return;
    
    if(flash) {
        CGDisplayFade(fadeToken, duration, kCGDisplayBlendNormal, kCGDisplayBlendSolidColor, flashColor.redComponent, flashColor.greenComponent, flashColor.blueComponent, true);
        usleep(duration*1000000);
    }
    else
        CGDisplayFade(fadeToken, duration, kCGDisplayBlendSolidColor, kCGDisplayBlendNormal,flashColor.redComponent, flashColor.greenComponent, flashColor.blueComponent, false);
    
}

-(void)awakeFromNib {
    
    for(NSLayoutConstraint *constraint in self.superview.superview.constraints) {
        if(constraint.constant == -256.f)
            _positionLeft = constraint;
        _positionLeft.constant = 0;
    }
    
    NSDictionary* notifications = @{
        NSWindowDidResizeNotification: @"screenResize",
                  @"SnappyShowCamera": @"showCamera:",
                   @"SnappyShowMedia": @"showMedia:"
    };
    
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
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
    
        stillImageOutput = [AVCaptureStillImageOutput new];
        if([session canAddOutput:stillImageOutput])
            [session addOutput:stillImageOutput];
    
        previewLayer               = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self->session];
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
-(void)screenResize {
    if(_positionLeft.constant != 0)
            _positionLeft.constant = -self.bounds.size.width;
    
    if(!self.layer)
        return;
    
    if([self.layer isKindOfClass:[AVPlayerLayer class]]) {
        CALayer *playerLayer = self.layer;
        CALayer *overlayLayer = playerLayer.sublayers[1];
        
        NSSize imageSize = ((NSImage*)overlayLayer.contents).size;
        NSSize layerSize = playerLayer.frame.size;
        
        CGFloat x = layerSize.width/2 - imageSize.width/2;
        CGFloat y = layerSize.height/2 - imageSize.height/2;
        
        overlayLayer.frame = NSMakeRect(x, y, imageSize.width, imageSize.height);
    }
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
-(void)showAndUseCamera:(BOOL)showCamera {
    _positionLeft.animator.constant = 0;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowingCamera"
                                                            object:self];
    
    if(showCamera)
        [self cleanStart];
}
-(void)show {
    [self showAndUseCamera:YES];
}
-(void)hide {
    _positionLeft.animator.constant = -self.bounds.size.width;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ClosingCamera"
                                                            object:self];
    [self cleanStop];
}

-(NSView*)photoTools {
    return (NSView*)(self.superview.subviews[1]);
}
-(id)photoToolsSubview:(Class)class {
    for(NSView* subview in [self photoTools].subviews) {
        if([subview isKindOfClass:class]) return subview;
    }
    return nil;
}


-(SMPhotoToolsView*)photoToolsView {
    return [self photoToolsSubview:[SMPhotoToolsView class]];
}
-(NSPopUpButton*)filterList {
    return [self photoToolsSubview:[NSPopUpButton class]];
}
-(SMPhotoButton*)photoBtn {
    return [self photoToolsSubview:[SMPhotoButton class]];
}
-(SMQuitMediaButton*)cancelBtn {
    return [self photoTools].subviews[2];
}


-(void)setShowFilterList:(BOOL)val {
    showFilterList = val;
    [self filterList].animator.alphaValue = val;
}
-(void)setShowPhotoBtn:(BOOL)val {
    showPhotoBtn = val;
    if(val)
       [[self photoBtn] show];
    else
        [[self photoBtn] hide];
}
-(void)setShowCancelBtn:(BOOL)val {
    showCancelBtn = val;
    if(val)
        [[self cancelBtn] show];
    else
        [[self cancelBtn] hide];
}
-(void)setShowPhotoTools:(BOOL)val {
    showPhotoTools = val;
    if(val)
        [[self photoToolsView] show];
    else
        [[self photoToolsView] hide];
}


-(NSView*)loadingView {
    return [self photoToolsSubview:[SMLoadingView class]];
}
-(NSProgressIndicator*)loadingView_spin {
    return [self loadingView].subviews[1];
}
-(void)showLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self loadingView] setHidden:NO];
        [[self loadingView_spin] startAnimation:nil];
    });
}
-(void)hideLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self loadingView] setHidden:YES];
        [[self loadingView_spin] stopAnimation:nil];
    });
}

-(void)setFilter:(CIFilter*)filter {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showLoading];
        
        if(session.isRunning)
            self.layer.filters = (filter ? @[filter] : nil);
        
        [self hideLoading];
    });
}


-(void)cleanStart {
    currentImage        = nil;
    self.layer          = previewLayer;
    self.showCancelBtn  = NO;
    self.showPhotoBtn   = YES;
    self.showFilterList = YES;
    self.showPhotoTools = YES;
    
    if(!session.isRunning) {
        [self showLoading];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [session performSelectorOnMainThread:@selector(startRunning) withObject:nil waitUntilDone:YES];
            sleep(2);
            [self hideLoading];
        });
    }
    
    [self resetSubviews];
}
-(void)cleanStop {
    self.layer = [CALayer new];
    if(session.isRunning)
            [session stopRunning];
    [self resetSubviews];
}
-(void)resetSubviews {
    NSView* photoTools = [self photoTools];
    photoTools.layer = [CALayer new];
}
-(void)showImageFile:(NSString*)path {
    NSImage *sourceImage = [[NSImage alloc] initWithContentsOfFile:path];
    [self showImage:sourceImage];
}
-(void)showImage:(NSImage*)image {
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
        CALayer *overlayLayer = [CALayer new];
        NSImage *overlayImage = [[NSImage alloc] initWithContentsOfFile:overlay];
        overlayLayer.contents = overlayImage;
        [playerLayer addSublayer:overlayLayer];
        
        [self screenResize];
    }
    
    [player play];
    
    
}
-(void)showMedia:(NSNotification*)notif {
    if(!notif)
        return;
    NSDictionary *urls = notif.object;
    
    if(!urls)
        return;
    
    NSString* path = urls[@"filePath"];
    
    NSLog(@"Urls = %@, path %@", urls, path);
    if(_positionLeft.animator.constant != 0)
        [self showAndUseCamera:NO];
    
    [self cleanStop];
    self.showCancelBtn  = YES;
    self.showPhotoBtn   =
    self.showFilterList =
    self.showPhotoTools = NO;
    
    if([path hasSuffix:@"jpg"] || [path hasSuffix:@"jpeg"] || [path hasSuffix:@"png"])
        [self showImageFile:path];
    else if([path hasSuffix:@"mp4"])
        [self showVideo:urls];
    
    [self resetSubviews];
}


+(BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector {
    return NO;
}

@end
