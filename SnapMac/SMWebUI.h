//
//  SMWebUI.h
//  SnapMac
//
//  Created by Fathy B on 01/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "SMClient.h"
#import "SMJSClient.h"
#import "SnapJS.h"

IB_DESIGNABLE
@interface SMWebUI : WebView

@property SMJSClient* jsClient;
@property SnapJS* SnapJS;

-(void)script:(NSString*)commande;

@end
