//
//  SMFileCollector.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMFileCollector.h"
#import "SMClient.h"

@implementation SMFileCollector

+ (NSString*) mimeTypeForFileAtPath: (NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    
    NSString *r = [NSString stringWithFormat:@"%@", mimeType];
    CFRelease(mimeType);
    return r;
}
+(NSString*)saveSnap:(NSString*)snap withData:(NSData*)data {
    
    NSString *directory = [NSString stringWithFormat:@"%@/SnapMac", NSHomeDirectory()];
    
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:directory isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error while creating SnapMac directory");
    
    NSString *file = [NSString stringWithFormat:@"%@/%@", directory, snap];
    BOOL written = [data writeToFile:file atomically:YES];
    
    if(!written) {
        return nil;
    }
    
    NSDictionary *filetype = [SMClient fileTypeForFile:file];
    
    NSString *newPath = [NSString stringWithFormat:@"%@.%@", file, filetype[@"extension"]];
    
    [[NSFileManager defaultManager] moveItemAtPath:file toPath:newPath error:nil];
    
    return newPath;
    /*
    //
    NSString *directory = [NSString stringWithFormat:@"%@/SnapMac", NSHomeDirectory()];
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:directory isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@", directory);
    SMMediaType mediaType = [SMClient typeForData:result];
    NSString *ext = [SMFileCollector mimeTypeForFileAtPath:<#(NSString *)#>
                     
    NSString *file = [NSString stringWithFormat:@"%@/SnapMac/%@.%@", NSHomeDirectory(), snap, ext];
    
    if(![result writeToFile:file atomically:YES]) NSLog(@"Erreur pour écrire %@ %@", snap, result);
    
    
    if(mediaType == SMVideoMP4) {
        [self buildThumbForFile:snap isSnap:YES];
    }*/
    return nil;
}

@end
