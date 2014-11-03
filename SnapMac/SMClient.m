//
//  SMClient.m
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import "SMClient.h"
#import "SMConnection.h"
#import "SMImage.h"
#import "SMJSClient.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonCrypto.h>
#import <AVFoundation/AVFoundation.h>
#import <QTKit/QTKit.h>

static SMClient *SMClientSharedInstance;

@implementation SMClient

-(instancetype)init {
    self = [super init];
    SMClientSharedInstance = self;
    return self;
}
+(instancetype)sharedClient {
    return SMClientSharedInstance;
}
+(SMClient*)clientWithLogin:(NSString*)login andPassword:(NSString*)password {
    SMClient *client = [SMClient new];
    [client setLogin:login];
    [client setPassword:password];
    return client;
}
+(SMClient*)clientWithAuthToken:(NSString*)authToken andLogin:(NSString*)login {
    SMClient *client = [SMClient new];
    [client setLogin:login];
    [client setAuthToken:authToken];
    return client;
}
-(void)setLogin:(NSString *)login {
    _login = login;
    if(!login || ![login isKindOfClass:[NSString class]]) {
        NSLog(@"Paramètre vide non engistrer (%@)", login);
        return;
    }
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:login forKey:@"SMLogin"];
}
-(void)setAuthToken:(NSString *)authToken {
    _authToken = authToken;
    if(!authToken || ![authToken isKindOfClass:[NSString class]]) {
        NSLog(@"Paramètre vide non engistrer (%@)", authToken);
        return;
    }
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:authToken forKey:@"SMAuthToken"];
}
+(NSString *)uuidString {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidString;
}
+(NSString*)hexForData:(NSData*)data {
    return [SMClient hexForData:data inRange:NSMakeRange(0, data.length)];
}
+(NSString*)hexForData:(NSData*)data inRange:(NSRange)range {
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    if (!dataBuffer)
        return [NSString string];
    NSUInteger dataLength  = range.length;
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (unsigned long i = range.location; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    return [NSString stringWithString:hexString];
}
+(SMMediaType)typeForData:(NSData*)data {
    NSDictionary *filetype = [SMClient fileTypeForData:data];
    return [SMClient typeForFiletype:filetype];
}
+(SMMediaType)typeForFiletype:(NSDictionary*)filetype {
    NSString *type = filetype[@"extension"];
    NSDictionary *strToSM = @{
        @"mp4": @(SMVideoMP4),
        @"jpg": @(SMImageJPG),
        @"zip": @(SMZippedMedia)
    };
    return ((NSNumber*)(strToSM[type] ? strToSM[type] : @(SMMediaUnknown))).intValue;
}
+(NSString*)typeToString:(SMMediaType)type {
    NSString* typeStr = @"";
    switch (type) {
        case SMImageJPG:
            typeStr = @"jpg";
            break;
        case SMVideoMP4:
            typeStr = @"mp4";
            break;
        case SMZippedMedia:
            typeStr = @"zip";
            break;
        case SMMediaUnknown:
            typeStr = @"";
            break;
    }
    return typeStr;
}
-(NSString*)getSnap:(NSString*)snap {
    
    NSMutableDictionary *endPointData = [SMConnection genericDataWithToken:_authToken];
    endPointData[@"username"] = _login;
    endPointData[@"id"] = snap;
    NSData *data = [SMConnection requestToURL:@"/ph/blob" withData:endPointData asData:YES];
    
    NSData *encryptionKey = [@"M02cnQ51Ji97vwT4" dataUsingEncoding:NSASCIIStringEncoding];
    NSData *result = nil;
    unsigned char cKey[16];
    bzero(cKey, sizeof(cKey));
    [encryptionKey getBytes:cKey length:16];
    
    size_t bufferSize = [data length];
    void * buffer = malloc(bufferSize);
    
    size_t decryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionECBMode,
                                          cKey,
                                          16,
                                          NULL,
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &decryptedSize);
    
    if (cryptStatus == kCCSuccess)
        result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
    else
        NSLog(@"Erreur lors du décryptage!");
    //
    NSString *directory = [NSString stringWithFormat:@"%@/SnapMac", NSHomeDirectory()];
    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:directory isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@", directory);
    SMMediaType mediaType = [SMClient typeForData:result];
    NSString *ext = [SMClient typeToString:mediaType];
    //if([ext isEqualToString:@""]) { NSLog(@"nopynopa %@", snap);return @""; }
    NSString *file = [NSString stringWithFormat:@"%@/SnapMac/%@.%@", NSHomeDirectory(), snap, ext];
    
    if(![result writeToFile:file atomically:YES]) NSLog(@"Erreur pour écrire %@ %@", snap, result);
    
    
    if(mediaType == SMVideoMP4) {
        [self buildThumbForFile:snap isSnap:YES];
    }
    return file;
}
-(void)buildThumbForFile:(NSString*)file isSnap:(BOOL)isSnap {
    NSLog(@"Video trouvé, snap %@, isSnap : %d", [_notifier hasSnapSaved:file forNative:YES], isSnap);
    NSError *error;
    QTMovie *movie = [QTMovie movieWithFile:[_notifier hasSnapSaved:file forNative:YES] error:&error];
    if(error) {
        NSLog(@"Error = %@", error);
        return;
    }
    NSImage *thumb = [movie posterImage];
    NSString *thumbUrl = [NSString stringWithFormat:@"%@/SnapMac/%@_thumb.png", NSHomeDirectory(), file];
    BOOL saved = [thumb saveAsPNG:thumbUrl];
    NSLog(@"url = %@, thumb = %@, saved = %d", thumbUrl, thumb, saved);
    if(isSnap)
        [_notifier performSelector:@selector(foundThumbnail:forSnap:) withObject:thumbUrl withObject:file];
    else
        [_notifier performSelector:@selector(foundThumbnail:forStory:) withObject:thumbUrl withObject:file];
        
}
-(NSData*)padData:(NSData*)data {
    NSMutableData *tmpData = [data mutableCopy];
    
    int blockSize = 16;
    int charDiv = blockSize - ((tmpData.length + 1) % blockSize);
    

    NSMutableString *padding = [[NSMutableString alloc] initWithFormat:@"%c",(unichar)10];
    
    for (int c = 0; c <charDiv; c++) {
        [padding appendFormat:@"%c",(unichar)charDiv];
    }
    [tmpData appendData:[padding dataUsingEncoding:NSUTF8StringEncoding]];
    return tmpData;
}
-(void)sendMedia:(id)media toFriends:(NSString*)friends {
    if([media isKindOfClass:[NSImage class]]) {
        NSMutableDictionary *endPointData = [SMConnection genericDataWithToken:_authToken];
        endPointData[@"username"] = _login;
        endPointData[@"type"] = @"0";
        NSString *guuid = [NSString stringWithFormat:@"%@~%@", [_login uppercaseString], [[SMClient uuidString] lowercaseString]];
        endPointData[@"media_id"] = guuid;
        NSLog(@"endpoint = %@", endPointData);
        
        NSData *imgData = [(NSImage*)media dataForFileType:NSJPEGFileType];
        NSData *data = [self padData:imgData];
        
        NSData *encryptionKey = [@"M02cnQ51Ji97vwT4" dataUsingEncoding:NSASCIIStringEncoding];
        NSData *result = nil;
        
        unsigned char cKey[16];
        bzero(cKey, sizeof(cKey));
        [encryptionKey getBytes:cKey length:16];
    
        size_t bufferSize = [data length] +  kCCKeySizeAES128;
        void * buffer = malloc(bufferSize);
        
        void * strBuffer = malloc(data.length);
        bzero(strBuffer, sizeof(strBuffer));
        [data getBytes:strBuffer];
        
    
        size_t decryptedSize = 0;
        CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                              kCCAlgorithmAES128,
                                              kCCOptionECBMode,
                                              cKey,
                                              kCCKeySizeAES128,
                                              NULL,
                                              strBuffer,
                                              data.length,
                                              buffer,
                                              bufferSize,
                                          &decryptedSize);
        
        if(cryptStatus == kCCSuccess) {
            result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
            endPointData[@"data"] = result;
            [SMConnection requestToURL:@"/bq/upload" withData:endPointData andCallback:^(id result) {
                
                NSLog(@"result2 = %@", result);
                NSMutableDictionary *endPointData = [SMConnection genericDataWithToken:_authToken];
                endPointData[@"username"] = _login;
                endPointData[@"media_id"] = guuid;
                endPointData[@"recipient"] = friends;
                endPointData[@"time"] = @"5";
                endPointData[@"zipped"] = @"0";
                
                [SMConnection requestToURL:@"/bq/send" withData:endPointData andCallback:^(id result2) {
                    NSLog(@"result2 = %@", result2);
                }];
            }];
        }
        else {
            //callback(nil);;
        }
        
    }
}
-(void)getStory:(NSDictionary*)story withCallback:(SMCallback)callback {
    [self getStory:story[@"media_id"] withKey:story[@"media_key"] iv:story[@"media_iv"] andCallback:callback];
}
+ (NSData*)decryptData:(NSData*)data key:(NSData*)key iv:(NSData*)iv {
    NSData* result = nil;
    
    unsigned char cKey[kCCKeySizeAES256];
    bzero(cKey, sizeof(cKey));
    [key getBytes:cKey length:kCCKeySizeAES256];
    
    char cIv[kCCBlockSizeAES128];
    bzero(cIv, kCCBlockSizeAES128);
    if (iv) {
        [iv getBytes:cIv length:kCCBlockSizeAES128];
    }
    
    size_t bufferSize = [data length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t decryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          cKey,
                                          kCCKeySizeAES256,
                                          cIv,
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &decryptedSize);
    
    if (cryptStatus == kCCSuccess) {
        result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
    } else {
        free(buffer);
        NSLog(@"[ERROR] failed to decrypt| CCCryptoStatus: %d", cryptStatus);
    }
    
    return result;
}

+(NSData*)encrypt:(NSData*)data withKey:(NSString*)key {
    NSData *mData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    CCCryptorStatus ccStatus = kCCSuccess;
    
    
    size_t bytesNeeded = 0;
    
    ccStatus = CCCrypt(kCCEncrypt,
                       kCCAlgorithmAES,
                       kCCOptionECBMode | kCCOptionPKCS7Padding,
                       [mData bytes],
                       [mData length],
                       nil,
                       [data bytes],
                       [data length],
                       NULL,
                       0,
                       &bytesNeeded);
    
    if(kCCBufferTooSmall != ccStatus) {
        NSLog(@"Here it must return BUFFER TOO SMALL !!");
        return nil;
    }
    
    char* cypherBytes = malloc(bytesNeeded);
    size_t bufferLength = bytesNeeded;
    
    if(NULL == cypherBytes)
        NSLog(@"cypherBytes NULL");
    
    ccStatus = CCCrypt(kCCEncrypt,
                       kCCAlgorithmAES,
                       kCCOptionECBMode | kCCOptionPKCS7Padding,
                       [mData bytes],
                       [mData length],
                       nil,
                       [data bytes],
                       [data length],
                       cypherBytes,
                       bufferLength,
                       &bytesNeeded);
    
    if(kCCSuccess != ccStatus){
        NSLog(@"kCCSuccess NO!");
        return nil;
    }
    
    return [NSData dataWithBytes:cypherBytes length:bufferLength];
}
NSDictionary* errorDict(NSString* message, int code) {
    return @{
        @"error": message,
        @"code" : @(code)
    };
}
-(void)getStory:(NSString*)identifier withKey:(NSString*)keyString iv:(NSString*)ivString andCallback:(SMCallback)callback {
    NSString *storyPath = [NSString stringWithFormat:@"/bq/story_blob?story_id=%@", identifier];
    NSData *key = [NSData dataFromBase64String:keyString];
    NSData *iv = [NSData dataFromBase64String:ivString];
    [SMConnection getDataRequestToURL:storyPath andCallback:^(NSData* result) {
        
        NSData* decryptedData =  [SMClient decryptData:result key:key iv:iv];
        
        if(!decryptedData) {
            return callback(errorDict(NSLoc(@"Erreur de décryptage"), 3));
        }
        NSString *filename = [NSString stringWithFormat:@"%@/SnapMac/%@.%@", NSHomeDirectory(), identifier, [SMClient typeToString:[SMClient typeForData:decryptedData]]];
        
        BOOL decrypt = [decryptedData writeToFile:filename atomically:YES];
        if(!decrypt) {
            return callback(errorDict(NSLoc(@"Erreur lors de l'écriture du ficher"), 4));
        }
        callback(filename);
    }];
}
+(NSDictionary*)fileTypeForData:(NSData*)data {
    [data writeToFile:@"/tmp/snaptmp" atomically:YES];
    NSDictionary *result = [SMClient fileTypeForFile:@"/tmp/snaptmp"];
    [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/snaptmp" error:nil];
    return result;
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
-(NSString*)writeData:(NSData*)data toFile:(NSString*)filename withDatas:(NSDictionary*)datas {
    NSLog(@"Crypting file %@", filename);
    NSString* key = [NSMutableString stringWithFormat:@"%%%@__objc_sendmsgcryptdata_r1", _login];
    NSLog(@"key = %@", key);
    NSDictionary *plist = @{
        @"filename": @"",
        @"SMOptions": datas
    };
    return nil;
}
-(void)storiesWithCallback:(SMCallback)callback {
    [self requestTo:@"/bq/stories" andCallback:callback];
}
-(void)updatesWithCallback:(SMCallback)callback {
    [self requestTo:@"/bq/updates" andCallback:callback];
}
-(id)stories {
    return [self requestTo:@"/bq/stories"];
}
-(id)updates {
    return [self requestTo:@"/bq/updates"];
}
-(id)requestTo:(NSString*)url {
    return [self requestTo:url withData:@{}];
}
-(void)requestTo:(NSString*)url andCallback:(SMCallback)callback {
    [self requestTo:url withData:@{} andCallback:callback];
}
-(void)requestTo:(NSString*)url withData:(NSDictionary*)data andCallback:(SMCallback)callback {
    NSMutableDictionary *endPointData = [SMConnection genericDataWithToken:_authToken];
    endPointData[@"username"] = _login;
    for(NSString *key in data.allKeys)
        endPointData[key] = data[key];
    [SMConnection requestToURL:url withData:endPointData andCallback:^(NSString* rep) {
        NSError *error;
        NSDictionary *reponse = [NSJSONSerialization JSONObjectWithData:[rep dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        callback(reponse);
    }];
}
-(id)requestTo:(NSString*)url withData:(NSDictionary*)data {
    NSMutableDictionary *endPointData = [SMConnection genericDataWithToken:_authToken];
    endPointData[@"username"] = _login;
    for(NSString *key in data.allKeys)
        endPointData[key] = data[key];
    NSString *rep = [SMConnection requestToURL:url withData:endPointData];
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:[rep dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    if(error) {
        NSLog(@"Erreur = %@ pour %@", error, rep);
        return nil;
    }
    return json;
}
-(void)connectWithCallback:(SMCallback)callback {
    NSMutableDictionary *endPointData = [SMConnection genericData];
    [endPointData setValue:_login forKey:@"username"];
    [endPointData setValue:_password forKey:@"password"];
    [SMConnection requestToURL:@"/bq/login" withData:endPointData andCallback:^(NSString* data) {
        NSError *error;
        NSDictionary *reponse = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        if(error) {
            NSLog(@"Erreur du traitement JSON");
            callback(nil);
            return;
        }
        if([reponse[@"logged"] isEqual:@YES]) {
            NSLog(@"Connécté! Auth Token = %@", reponse[@"auth_token"]);
            [self setAuthToken:reponse[@"auth_token"]];
            _password = @"";
            callback(nil);
        }
        else {
            callback(nil);
        }
        
    }];
}
-(BOOL)connect {
    NSMutableDictionary *endPointData = [SMConnection genericData];
    [endPointData setValue:_login forKey:@"username"];
    [endPointData setValue:_password forKey:@"password"];
    NSString* data = [SMConnection requestToURL:@"/bq/login" withData:endPointData];
    NSError *error;
    NSDictionary *reponse = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    if(error) {
        NSLog(@"Erreur du traitement JSON");
        return NO;
    }
    if([reponse[@"logged"] isEqual:@YES]) {
        NSLog(@"Connécté! Auth Token = %@", reponse[@"auth_token"]);
        [self setAuthToken:reponse[@"auth_token"]];
        _password = @"";
        return YES;
    }
    else {
        NSLog(@"Reponse = %@", reponse);
        return NO;
    }
}
-(BOOL)connected {
    return !(_authToken == nil || [_authToken isEqualToString:@""]);
}
@end
