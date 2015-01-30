//
//  IntertwineManager.h
//  Sign On
//
//  Created by Ben Rooke on 1/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IntertwineManager : NSObject

+ (NSString*)filePath;

+ (void)createAccountFirst:(NSString*)first
                      last:(NSString*)last
                     email:(NSString*)email
                  facebook:(NSString*)facebookID
                  password:(NSString*)password
                completion:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) completion;
+ (void)emailSignOn:(NSString*)emailAddress password:(NSString*)password completion:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) completion;

+ (NSString*)getAccountID;
+ (BOOL)setAccountID:(NSString*)accountID;
+ (NSString*)accountIDFilePath;

+ (NSString*)getHash;
+ (BOOL)setHashkey:(NSString*)hashkey;

+ (NSMutableURLRequest*)getRequest:(NSString*)endpoint;
+ (void)sendRequest:(NSMutableURLRequest*)request response:(void (^)(id json, NSError* error, NSURLResponse *resp))responseBlock;




@end
