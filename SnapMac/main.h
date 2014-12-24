//
//  main.h
//  SnapMac
//
//  Created by Fathy B on 09/06/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//



#ifdef __OBJC__

#import <Cocoa/Cocoa.h>
void debugOutput(char* filename, const char* function, int linenumber, NSString* input, ...);
BOOL isYosemite();

#endif