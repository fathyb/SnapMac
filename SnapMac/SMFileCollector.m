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

#import "unzip.h"
#import <sys/stat.h>

#define dir_delimter '/'
#define MAX_FILENAME 512
#define READ_SIZE 8192

NSOperationQueue *thumbQueue;

@implementation SMFileCollector

+(void)parseZip:(NSString*)path withCallback:(SMCallback)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *identifier = path.stringByDeletingPathExtension.lastPathComponent;
        NSMutableDictionary *files = [NSMutableDictionary new];
        
        unzFile *zipfile = unzOpen(path.UTF8String);
        const char *zipDir = [path.stringByDeletingPathExtension stringByAppendingString:@".snpy"].UTF8String;
        mkdir(zipDir, S_IRWXU);
        chdir(zipDir);
        
        if(!zipfile) {
            callback(nil);
        }
        
        
        unz_global_info global_info;
        if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK) {
            printf("could not read file global info\n");
            unzClose(zipfile);
            callback(nil);
        }
        
        
        char read_buffer[ READ_SIZE ];
        
        
        uLong i;
        for(i = 0; i < global_info.number_entry; ++i) {
            
            unz_file_info file_info;
            char filename[MAX_FILENAME];
            if(unzGetCurrentFileInfo(zipfile,
                                     &file_info,
                                     filename,
                                     MAX_FILENAME,
                                     NULL, 0, NULL, 0) != UNZ_OK) {
                printf("could not read file info\n");
                unzClose(zipfile);
                callback(nil);
            }
            
            const size_t filename_length = strlen(filename);
            if(filename[filename_length-1] == dir_delimter) {
                mkdir(filename, S_IWOTH);
            }
            else {
                NSString *nsFilename = [NSString stringWithCString:filename
                                                          encoding:NSUTF8StringEncoding];
                BOOL isMedia   = [nsFilename hasPrefix:@"media"],
                     isOverlay = [nsFilename hasPrefix:@"overlay"];
                if(isMedia || isOverlay) {
                    if (unzOpenCurrentFile(zipfile) != UNZ_OK) {
                        printf("could not open file\n");
                        unzClose(zipfile);
                        callback(nil);
                    }
                    nsFilename = [@(isMedia ? "media_" : "overlay_") stringByAppendingString:identifier];
                    FILE *out = fopen(nsFilename.UTF8String, "wb" );
                    int error = UNZ_OK;
                    
                    do {
                        error = unzReadCurrentFile(zipfile, read_buffer, READ_SIZE);
                        if (error < 0) {
                            printf("error %d\n", error);
                            unzCloseCurrentFile(zipfile);
                            unzClose(zipfile);
                            callback(nil);
                        }
                        
                        if (error > 0) {
                            fwrite(read_buffer, error, 1, out);
                        }
                    } while(error > 0);
                    
                    files[isMedia ? @"media" : @"overlay"] = nsFilename;
                    
                    fclose(out);
                }
                
            }
            
            unzCloseCurrentFile(zipfile);
            
            if((i+1) < global_info.number_entry) {
                if(unzGoToNextFile(zipfile) != UNZ_OK) {
                    printf("cound not read next file\n");
                    unzClose(zipfile);
                    callback(nil);
                }
            }
        }
        
        unzClose(zipfile);
        callback(files);
    });
}
+(void)generateImageForFile:(NSString*)file andCallback:(SMCallback)callback {
    if(!thumbQueue) {
        thumbQueue = [NSOperationQueue new];
        thumbQueue.maxConcurrentOperationCount = 5;
    }
    [thumbQueue addOperationWithBlock:^{
        AVURLAsset *asset = [AVURLAsset.alloc initWithURL:[NSURL fileURLWithPath:file]
                                                  options:nil];

        AVAssetImageGenerator *generator = [AVAssetImageGenerator.alloc initWithAsset:asset];
        generator.appliesPreferredTrackTransform = YES;
        generator.maximumSize                    = NSMakeSize(500, 500);
    
    
        CMTime time = asset.duration;
        time.value  = 1000;
        
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            NSError *error = nil;
            CGImageRef imageRef = [generator copyCGImageAtTime:time
                                                    actualTime:nil
                                                         error:&error];
            NSImage *thumb = nil;
            if(error || !imageRef) {
                callback(error);
                NSLog(@"Error while generating thumb for file %@\nError : %@", file, error);
            }
            else {
                thumb = [NSImage.alloc initWithCGImage:imageRef size:NSZeroSize];
                CGImageRelease(imageRef);
            }
            
            if(!thumb) {
                NSLog(@"Error while generating thumb for file %@ \n Error : empty output", file);
                callback(nil);
            }
            else
                callback(thumb);
        }];
    }];
    
}
+(NSString*)mimeTypeForFileAtPath:(NSString *) path {
    if (![NSFileManager.defaultManager fileExistsAtPath:path]) {
        return nil;
    }
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)path.pathExtension, nil);
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
    NSString *dirPath  = [NSString stringWithFormat:@"%@/Snappy", NSHomeDirectory()],
             *thumb    = nil,
             *filePath = nil,
             *overlay  = nil;
    
    NSFileManager *fManager = NSFileManager.defaultManager;
    NSArray       *dirFiles = [fManager contentsOfDirectoryAtPath:dirPath
                                                            error:nil],
                  *files    = nil;
    NSPredicate *filePredicate    = [NSPredicate predicateWithFormat:@"(self CONTAINS %@) AND (self CONTAINS '.') "
                                                                        "AND !(self CONTAINS 'thumb') "
                                                                        "AND !(self CONTAINS 'snpy')"
                                                                        "AND !(self CONTAINS 'overlay')"
                                                                        "AND !(self CONTAINS 'zip')", media],
                *thumbPredicate   = [NSPredicate predicateWithFormat:@"(self CONTAINS %@) "
                                                                        "AND (self CONTAINS '.') "
                                                                        "AND  (self CONTAINS 'thumb')", media],
                *overlayPredicate = [NSPredicate predicateWithFormat:@"(self CONTAINS %@) "
                                                                        "AND (self CONTAINS '.') "
                                                                        "AND  (self CONTAINS 'overlay')", media],
                *snpyPredicate    = [NSPredicate predicateWithFormat:@"(self CONTAINS %@) "
                                                                        "AND (self ENDSWITH '.snpy')", media];
    
    
    files = [dirFiles filteredArrayUsingPredicate:filePredicate];
    if(files && files.count)
        filePath = files[0];
    
    files = [dirFiles filteredArrayUsingPredicate:thumbPredicate];
    if(files && files.count)
        thumb = files[0];
    
    files = [dirFiles filteredArrayUsingPredicate:overlayPredicate];
    if(files && files.count)
        overlay = files[0];
    
    if(!filePath) {
        files = [dirFiles filteredArrayUsingPredicate:snpyPredicate];
        if(files && files.count) {
            for(NSString* dir in files) {
                NSArray *snpyDirFiles = [fManager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/Snappy/%@", NSHomeDirectory(), dir]
                                                                      error:nil],
                        *snpyFiles = nil;
            
                snpyFiles = [snpyDirFiles filteredArrayUsingPredicate:filePredicate];
                if(snpyFiles && snpyFiles.count)
                    filePath = [NSString stringWithFormat:@"%@/%@", dir, snpyFiles[0]];
                
                snpyFiles = [snpyDirFiles filteredArrayUsingPredicate:thumbPredicate];
                if(snpyFiles && snpyFiles.count)
                    thumb = [NSString stringWithFormat:@"%@/%@", dir, snpyFiles[0]];
                
                snpyFiles = [snpyDirFiles filteredArrayUsingPredicate:overlayPredicate];
                if(snpyFiles && snpyFiles.count)
                    overlay = [NSString stringWithFormat:@"%@/%@", dir, snpyFiles[0]];
            
            }
        }
    }
    
    if(!filePath)
        return callback(nil);
    
    filePath = [NSString stringWithFormat:@"%@/%@", dirPath, filePath];
    thumb    = thumb ? [NSString stringWithFormat:@"%@/%@", dirPath, thumb] : filePath;
    overlay = overlay ? [NSString stringWithFormat:@"%@/%@", dirPath, overlay] : @"";
    
    if(thumb == filePath && ([filePath hasSuffix:@"mp4"] || [filePath hasSuffix:@"3gpp"])) {
        
        [SMFileCollector generateImageForFile:filePath
                                  andCallback:^(NSImage* image) {
            if(!image)
                return callback(@{
                           @"thumb": thumb,
                           @"filePath": filePath,
                           @"overlay": overlay
                           });
            NSString *thumbUrl = [NSString stringWithFormat:@"%@/%@_thumb.png", dirPath, media];
            [image saveAsFileType:NSPNGFileType
                           toFile:thumbUrl];
                
            callback(@{
                        @"thumb": thumbUrl,
                        @"filePath": filePath,
                        @"overlay": overlay
                    });
        }];
    }
    else
        callback(@{
                @"thumb": thumb,
                @"filePath": filePath,
                @"overlay": overlay
            });
}
+(NSDictionary*)fileTypeForFile:(NSString*)path {
    NSTask *task = NSTask.new;
    task.launchPath = @"/usr/bin/file";
    task.arguments  = @[@"-b", @"--mime-type", path];
    
    NSPipe *pipe = NSPipe.pipe;
    task.standardOutput = pipe;
    
    NSFileHandle *file = pipe.fileHandleForReading;
    
    [task launch];
    [task waitUntilExit];
    
    NSData *returnedBuffer = file.readDataToEndOfFile;
    NSString *returned = [NSString.alloc initWithData:returnedBuffer
                                               encoding:NSUTF8StringEncoding];
              returned = [returned stringByReplacingOccurrencesOfString:@"\n"
                                                             withString:@""];
    
    NSArray *results = [returned componentsSeparatedByString:@"/"];
    NSString *extension = results[1];
    
    if([extension isEqualToString:@"jpeg"])
        extension = @"jpg";
        
    
    return @{
             @"type": results[0],
             @"extension": extension
             };
    
}

+(void)save:(NSString*)identifier withData:(NSData*)data andCallback:(SMCallback)callbackBlock {
    
    SMCallback __block callback = callbackBlock;
    
    NSString*      directory   = [NSString stringWithFormat:@"%@/Snappy", NSHomeDirectory()];
    NSFileManager* fileManager = NSFileManager.defaultManager;
    
    if(![fileManager fileExistsAtPath:directory])
        if(![fileManager createDirectoryAtPath:directory
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:nil])
            NSLog(@"Error while creating SnapMac directory");
    
    BOOL overlay = [identifier hasPrefix:@"overlay"],
         media   = [identifier hasPrefix:@"media"],
         writeFile = YES;
    NSString *file = nil;
    
    if(overlay || media) {
        NSString *realId  = [identifier stringByReplacingOccurrencesOfString:overlay ? @"overlay_" : @"media_"
                                                                  withString:@""];
        
        file = [NSString stringWithFormat:@"%@/%@.snpy/%@", directory, realId, identifier];
        if([fileManager fileExistsAtPath:file])
            writeFile = NO;
    }
    if(writeFile) {
        file = [NSString stringWithFormat:@"%@/%@", directory, identifier];
        BOOL written = [data writeToFile:file
                               atomically:YES];
        
        if(!written) {
            callback(nil);
            return;
        }
    }
    
    NSString *extension = [SMFileCollector fileTypeForFile:file][@"extension"],
             *newPath = overlay || media ?
                    [file stringByAppendingString:[@"." stringByAppendingString:extension]] :
                    [NSString stringWithFormat:@"%@.%@", file, extension];
    
    [fileManager moveItemAtPath:file
                         toPath:newPath
                          error:nil];
    
    if([extension isEqualToString:@"mp4"] || [extension isEqualToString:@"3gpp"]) {
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
    else if([extension isEqualToString:@"zip"]) {
        [self parseZip:newPath withCallback:^(NSDictionary *files) {
            int __block filesTreated = 0;
            
            for(NSString *key in files.allKeys) {
                [SMFileCollector save:[NSString stringWithFormat:@"%@_%@", key, identifier]
                             withData:nil
                          andCallback:^(NSDictionary* urls) {
                              filesTreated++;
                              if(filesTreated == files.count) {
                                  [SMFileCollector urlsForMedia:identifier
                                                    andCallback:^(NSDictionary* urls) {
                                                        callback(urls);
                                  }];
                                  [fileManager removeItemAtPath:newPath
                                                          error:nil];
                              }
                }];
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
