//
//  NSImage+SMImage.h
//  SnapMac
//
//  Created by Fathy B on 20/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (SMImage)

-(void)setFilter:(CIFilter*)filter;
-(NSImage*)imageResizedToSize:(NSSize)newSize;
-(void)flipImage;
-(NSData*)dataForFileType:(NSBitmapImageFileType)filetype;
-(BOOL)saveAsFileType:(NSBitmapImageFileType)filetype toFile:(NSString*)fileName;
-(BOOL)saveAsPNG:(NSString*)fileName;

@end
