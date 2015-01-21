//
//  SMAndroidSync.h
//  SnapMac
//
//  Created by Fathy B on 07/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMAndroidSync : NSObject <NSXMLParserDelegate>

@property (nonatomic, strong) NSString* user;
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic, strong) NSString* current;
@property (nonatomic, strong) SMCallback callback;

@end
