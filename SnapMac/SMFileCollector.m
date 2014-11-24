//
//  SMFileCollector.m
//  SnapMac
//
//  Created by Fathy Boundjadj  on 20/10/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMFileCollector.h"
#import "SMImage.h"
#import <AVFoundation/AVFoundation.h>

@implementation SMFileCollector

+(void)generateImageForFile:(NSString*)file andCallback:(SMCallback)callback {
    
    NSImage __block *thumb = nil;
    AVURLAsset      *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:file]
                                                     options:nil];

    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize                    = NSMakeSize(500, 500);
    
    
    CMTime time = [asset duration];
    time.value  = 1000;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError    *error   = nil;
        CGImageRef imageRef = [generator copyCGImageAtTime:time actualTime:nil error:&error];
        
        if(error || !imageRef)
            callback(error);
        else {
            thumb = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
            CGImageRelease(imageRef);
        }
        
        if(!thumb)
            callback(nil);
        else
            callback(thumb);
    });
    /*
    [generator generateCGImagesAsynchronouslyForTimes:@[
                                                        [NSValue valueWithCMTime:CMTimeMakeWithSeconds(0, duration)]
                                                      ]
                                    completionHandler:^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                                        
                                        
                                        if (result != AVAssetImageGeneratorSucceeded)
                                            callback(nil);
                                        else {
                                            thumb = [[NSImage alloc] initWithCGImage:im size:NSZeroSize];
                                            CGImageRelease(im);
                                            if(!thumb || !im)
                                                callback(nil);
                                            
                                            callback(thumb);
                                        }
    }];*/
    
}
+(NSString*)mimeTypeForFileAtPath:(NSString *) path {
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

+(void)urlsForMedia:(NSString*)media andCallback:(SMCallback)callback {
    NSString* dirPath   = [NSString stringWithFormat:@"%@/Snappy", NSHomeDirectory()];
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:dirPath];
    
    NSString *thumb,
             *filePath,
             *filename;
    
    media = [media substringWithRange:NSMakeRange(0, media.length -1)];
    
    while ((filename = [dirEnum nextObject])) {
        if([filename hasPrefix:[NSString stringWithFormat:@"%@_thumb", media]])
            thumb = filename;
        else if([filename hasPrefix:media])
            filePath = filename;
    }
    
    if(!filePath)
        return callback(nil);
    
    filePath = [NSString stringWithFormat:@"%@/%@", dirPath, filePath];
    
    if(thumb)
        thumb = [NSString stringWithFormat:@"%@/%@", dirPath, thumb];
    else if([filePath hasSuffix:@"png"] || [filePath hasSuffix:@"jpg"] || [filePath hasSuffix:@"jpeg"])
        thumb = filePath;
    else
        thumb = @"";
    
    if(!thumb && [filePath hasSuffix:@"mp4"]) {
        [SMFileCollector generateImageForFile:filePath
                                  andCallback:^(NSImage* image) {
            if(!image)
                return callback(@{
                           @"thumb": thumb,
                           @"filePath": filePath
                           });
            NSString *thumbUrl = [NSString stringWithFormat:@"%@/%@_thumb.png", dirPath, media];
            [image saveAsFileType:NSPNGFileType
                           toFile:thumbUrl];
                
            callback(@{
                        @"thumb": thumbUrl,
                        @"filePath": filePath
                    });
        }];
    }
    else
        callback(@{
                @"thumb": thumb,
                @"filePath": filePath
            });
}
+(NSDictionary*)fileTypeForFile:(NSString*)path {
    NSTask *task = [NSTask new];
    [task setLaunchPath: @"/usr/bin/file"];
    [task setArguments: @[@"-b", @"--mime-type", path]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit];
    NSData *data = [file readDataToEndOfFile];
    NSString *returned = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSMutableArray *results = [[returned componentsSeparatedByString:@"/"] mutableCopy];
    NSString *extension = results[1];
    if([extension isEqualToString:@"jpeg"]) extension = @"jpg";
    return @{
             @"type": results[0],
             @"extension": extension
             };
    
}
+(void)save:(NSString*)identifier withData:(NSData*)data andCallback:(SMCallback)callback {
    
    NSString*      directory   = [NSString stringWithFormat:@"%@/Snappy", NSHomeDirectory()];
    BOOL           isDir       = NO;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if(![fileManager fileExistsAtPath:directory isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error while creating SnapMac directory");
    
    NSString* file    = [NSString stringWithFormat:@"%@/%@", directory, identifier];
    BOOL      written = [data writeToFile:file atomically:YES];
    
    if(!written) {
        callback(nil);
        return;
    }
    
    NSString *extension = [SMFileCollector fileTypeForFile:file][@"extension"];
    NSString *newPath   = [NSString stringWithFormat:@"%@.%@", file, extension];
    
    [[NSFileManager defaultManager] moveItemAtPath:file toPath:newPath error:nil];
    
    if([extension isEqualToString:@"mp4"]) {
        [SMFileCollector generateImageForFile:newPath
                                  andCallback:^(NSImage* image) {
            if(!image)
                callback(@{
                           @"thumb": newPath,
                           @"filePath": newPath
                           });
            else {
                NSString *thumb = [NSString stringWithFormat:@"%@_thumb.png", file];
                [image saveAsFileType:NSPNGFileType
                               toFile:thumb];
                
                callback(@{
                           @"thumb": thumb,
                           @"filePath": newPath
                           });
            }
        }];
    }
    else
        callback(@{
                   @"thumb": newPath,
                   @"filePath": newPath
                   });
}

@end
