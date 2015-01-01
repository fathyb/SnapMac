//
//  SMWebUI.h
//  SnapMac
//
//  Created by Fathy B on 01/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <Webkit/WebFrameLoadDelegate.h>

@class SnapJS;
@interface SMWebUI : WebView


-(void)script:(NSString*)commande;

@property (nonatomic) SnapJS *snapJS;

@end
