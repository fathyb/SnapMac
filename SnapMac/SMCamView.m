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
        if([[_settings objectForKey:@"SMUseFlash"] boolValue])
            [self flashScreen:YES];
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in stillImageOutput.connections) {
            for (AVCaptureInputPort *port in [connection inputPorts]) {
                if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection)
                break;
        }
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
            if([[_settings objectForKey:@"SMUseFlash"] boolValue])
                [self flashScreen:NO];
            
            if(!error && imageSampleBuffer) {
                [session performSelectorOnMainThread:@selector(stopRunning) withObject:nil waitUntilDone:NO];
                
                NSData* jpegData        = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                NSImage* oldImage       = [[NSImage alloc] initWithData:jpegData];
                NSLog(@"oldimage size = %f, %f", oldImage.size.width, oldImage.size.height);
                /*     width            height
                    1280/2 = 640     1024/2 = 512
                    640-240 = 300    512-360 = 125
                 */
                NSRect newRect          = NSMakeRect(300, 125, 480, 720);
                CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[oldImage TIFFRepresentation], nil);
                CGImageRef nImageRef    = CGImageSourceCreateImageAtIndex(source, 0, nil);
                CGImageRef imageRef     = CGImageCreateWithImageInRect(nImageRef, newRect);
                NSImage* newImage       = [[NSImage alloc] initWithCGImage:imageRef size:newRect.size];
                NSArray* filters        = previewLayer.filters;
                
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
    CGError           error = CGAcquireDisplayFadeReservation(duration*2, &fadeToken);
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenResize) name:NSWindowDidResizeNotification object:nil];
    [self showLoading];
    [SMSettings addOnloadBlock:^(SMSettings* settings) {
        _settings = settings;
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
    
        SEL useCIFilters = NSSelectorFromString(@"setLayerUsesCoreImageFilters:");
        if([self respondsToSelector:useCIFilters])
            [self performSelectorInBackground:useCIFilters withObject:@YES];
    
        session = [AVCaptureSession new];
        [session beginConfiguration];
        [session setSessionPreset:AVCaptureSessionPresetPhoto];
        [session commitConfiguration];
    
        for(AVCaptureDevice *device in [AVCaptureDevice devices]) {
            if([device hasMediaType:AVMediaTypeVideo] || [device hasMediaType:AVMediaTypeMuxed]) {
                AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                if (error) {
                    NSLog(@"deviceInputWithDevice failed with error %@", [error localizedDescription]);
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
        previewLayer.opacity       = (isYosemite() ? .8 : 1);
        previewLayer.videoGravity  = AVLayerVideoGravityResizeAspectFill;
        previewLayer.masksToBounds = YES;
        
        previewLayer.connection.automaticallyAdjustsVideoMirroring = NO;
        previewLayer.connection.videoMirrored                      = YES;
        
        for(NSLayoutConstraint *constraint in self.superview.superview.constraints) {
            if(constraint.constant == -256.f)
                _positionLeft = constraint;
            _positionLeft.constant = 0;
        }
        
        
        
        [self cleanStart];
        [self hideLoading];
    });
}
-(void)screenResize {
    if(_positionLeft.constant != 0)
        _positionLeft.constant = -self.bounds.size.width;
}
-(void)show {
    _positionLeft.animator.constant = 0;
    [self cleanStart];
}
-(void)hide {
    _positionLeft.animator.constant = -self.bounds.size.width;
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
    if(!session.isRunning)
            [session startRunning];
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
    [self cleanStop];
    self.showCancelBtn  = YES;
    self.showPhotoBtn   =
    self.showFilterList =
    self.showPhotoTools = NO;
    self.layer.contents = [image imageResizedToSize:self.bounds.size];
    [self resetSubviews];
}


@end
