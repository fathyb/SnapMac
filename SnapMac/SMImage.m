//
//  NSImage+SMImage.m
//  SnapMac
//
//  Created by Fathy B on 20/04/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMImage.h"
#import <Quartz/Quartz.h>

@implementation NSImage (SMImage)

-(void)setFilter:(CIFilter*)filter {
    if(!filter) return;
    NSSize size = [self size];
    NSRect bounds = { NSZeroPoint, size };
    [self lockFocus];
    [filter setValue:[CIImage imageWithData:[self TIFFRepresentation]] forKey:@"inputImage"];
    [[filter valueForKey:@"outputImage"] drawAtPoint:NSZeroPoint
                                                 fromRect:bounds
                                                operation:NSCompositeSourceOver
                                                 fraction:1.0];
    [self unlockFocus];
}

-(NSData*)dataForFileType:(NSBitmapImageFileType)filetype {
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    return [imageRep representationUsingType:filetype properties:imageProps];
}
-(BOOL)saveAsFileType:(NSBitmapImageFileType)filetype toFile:(NSString*)fileName {
    NSData *imageData = [self dataForFileType:filetype];
	return [imageData writeToFile:fileName atomically:NO];
}
-(BOOL)saveAsPNG:(NSString*)fileName {
	return [self saveAsFileType:NSPNGFileType toFile:fileName];
}
-(NSImage*)imageResizedToSize:(NSSize)newSize {
	NSSize imageSize = self.size;
	float width		 = imageSize.width;
	float height	 = imageSize.height;
	
	float newWidth  = newSize.width;
	float newHeight = newSize.height;
	
	float scaleFactor  = 0.0;
	float scaledWidth  = newWidth;
	float scaledHeight = newHeight;
	
	NSPoint thumbnailPoint = NSZeroPoint;
	
	if(!NSEqualSizes(imageSize, newSize)) {
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
	
	NSImage* newImage = [[NSImage alloc] initWithSize:newSize];
	
	[newImage lockFocus];
	
	NSRect thumbnailRect;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[self drawInRect: thumbnailRect
			fromRect: NSZeroRect
		   operation: NSCompositeSourceOver
			fraction: 1.0];
	
	[newImage unlockFocus];
	
	return newImage;
}
-(void)flipImage {
	
	NSSize	 existingSize	= self.size;
	NSSize	 newSize		= NSMakeSize(existingSize.width, existingSize.height);
		
	[self lockFocus];
		
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		
	NSAffineTransform* t = [NSAffineTransform transform];
	[t translateXBy:existingSize.width yBy:0];
	[t scaleXBy:-1 yBy:1.0];
	[t concat];
		
	[self drawAtPoint: NSZeroPoint
			  fromRect: NSMakeRect(0, 0, newSize.width, newSize.height)
			 operation: NSCompositeSourceOver
			  fraction: 1.0];

	[self unlockFocus];
}

@end
