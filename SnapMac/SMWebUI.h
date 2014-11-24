//
//  SMWebUI.h
//  SnapMac
//
//  Created by Fathy B on 01/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "SnapJS.h"

@interface SMWebUI : WebView

@property SnapJS* SnapJS;

-(void)script:(NSString*)commande;

@end
