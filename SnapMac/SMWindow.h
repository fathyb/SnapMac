//
//  SMWindow.h
//  Snappy
//
//  Created by Fathy Boundjadj  on 07/11/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SMWebUI.h"

@interface SMWindow : NSWindow

@property (nonatomic) SMWebUI* webUI;
@property (nonatomic) NSWindow* aboutWindow;
@property (nonatomic) NSWindow* settingsWindow;


@end
