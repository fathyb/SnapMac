//
//  SMClient.h
//  SnapMac
//
//  Created by Fathy B on 31/03/2014.
//  Copyright (c) 2014 Fathy B. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMConnection.h"

typedef NS_ENUM(NSUInteger, SMError) {
    SMUnknownError      = 0,
    SMLoginError        = 1,
    SMPasswordError     = 2,
    SMHTTPError         = 3,
    SMNoConnectionError = 4
};

typedef NS_ENUM(NSUInteger, SMMediaType) {
    SMMediaUnknown  = 0,
    SMImageJPG      = 1,
    SMVideoMP4      = 2,
    SMZippedMedia   = 3
};

@interface SMClient : NSObject

+(instancetype)sharedClient;
+(NSString *)uuidString;
+(SMClient*)clientWithLogin:(NSString*)login andPassword:(NSString*)password;
/*! Call callback parameter with the decrypted story (SMStory Object) as param.
 \param story The story dictionnary obtained with the -storiesWithCallback:
 \param callback The callback that will be called with the decryped SMStory Object
 */
-(void)getStory:(NSDictionary*)story withCallback:(SMCallback)callback;
-(void)getStory:(NSString*)identifier withKey:(NSString*)keyString iv:(NSString*)ivString andCallback:(SMCallback)callback;
-(void)storiesWithCallback:(SMCallback)callback;
-(id)stories;
-(void)updatesWithCallback:(SMCallback)callback;
-(void)requestTo:(NSString*)url andCallback:(SMCallback)callback;
-(void)requestTo:(NSString*)url withData:(NSDictionary*)data andCallback:(SMCallback)callback;
-(NSString*)getSnap:(NSString*)snap;
-(id)updates;
-(void)connectWithCallback:(SMCallback)callback;
-(BOOL)connect;
-(BOOL)connected;
-(void)sendMedia:(id)media toFriends:(NSString*)friends;
+(NSDictionary*)fileTypeForFile:(NSString*)path;

+(SMClient*)clientWithAuthToken:(NSString*)authToken andLogin:(NSString*)login;

@property (nonatomic) NSString* authToken;
@property (nonatomic) NSString* login;
@property (nonatomic) id notifier;
@property NSString* password;
@property SMError lastError;

@end
