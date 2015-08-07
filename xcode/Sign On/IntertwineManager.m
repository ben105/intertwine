//
//  IntertwineManager.m
//  Sign On
//
//  Created by Ben Rooke on 1/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "IntertwineManager.h"

AccountType _accountType;

@interface IntertwineManager ()

+(BOOL) isConnectionError:(NSError*)error HTTPResponse:(NSURLResponse*)response data:(NSData*)data;

@end

@implementation IntertwineManager

+ (NSData*)loadJSON:(id)object {
    /*
     * Convert the NSMutableDictionary into JSON data.
     */
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (error) {
        NSLog(@"Error occured trying to serialize to JSON data, when creating an event.");
        return nil;
    }
    return data;
}

NSString *_facebookID = nil;
NSString *_facebookName = nil;
NSString *_accountID = nil;
NSString *_hashkey = nil;
NSData *_deviceToken = nil;
const NSString *server = @"http://ec2-52-11-184-120.us-west-2.compute.amazonaws.com:5000";



+(BOOL) isConnectionError:(NSError*)error HTTPResponse:(NSURLResponse*)response data:(NSData*)data {
    NSString *error_message = nil;
    if ([(NSHTTPURLResponse*)response statusCode] / 200 != 1) {
        error_message = @"Invalid response from the server, please try again later.";
    } else if (error) {
        error_message = [error localizedDescription];
    } else if ([data length] == 0) {
        error_message = @"No data was returned from the server, please try again later.";
    }
    return error_message;
}



+ (NSString*)filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

#pragma mark - HTTP Requests

+ (NSMutableURLRequest*)getRequest {
    return [IntertwineManager getRequest:@""];
}

+ (NSMutableURLRequest*)getRequest:(NSString*)endpoint {
    endpoint = [endpoint stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *urlString = [server stringByAppendingString:endpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [IntertwineManager attachCredentialsToRequest:request];
    return request;
}

// TODO: CLean this up!
+ (void)sendRequest:(NSMutableURLRequest*)request response:(void (^)(id json, NSError* error, NSURLResponse *resp))responseBlock {
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError){
                                   NSLog(@"Error connecting: %@", connectionError.userInfo);
                                   responseBlock(nil, connectionError, response);
                               } else {
                                   if (data!=nil && [data length]) {
                                       NSError *jsonReadingError = nil;
                                       id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonReadingError];
                                       if (responseBlock == nil) {
                                           return;
                                       }
                                       if (jsonReadingError) {
                                           responseBlock(nil, jsonReadingError, response);
                                       } else {
                                           responseBlock(json, nil, response);
                                       }
                                   } else {
                                       if (responseBlock != nil) {
                                           responseBlock(nil, nil, response);
                                       }
                                   }
                               }
                           }];
}


#pragma mark - Device Token

+ (void) updateDeviceToken:(NSData*)deviceToken {
    NSLog(@"Updating device tokne: %@", deviceToken);
    NSMutableURLRequest *request = [IntertwineManager getRequest:@"/api/v1/device_token"];
    [IntertwineManager attachCredentialsToRequest:request];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:deviceToken];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if(connectionError) {
                                   NSLog(@"Connection error: %@", connectionError);
                               }
                           }];
}




#pragma mark - Account Management

+ (void)registeredFacebookID:(NSString*)facebookID username:(NSString*)username {
    _facebookID = facebookID;
    _facebookName = username;
}

+ (NSString*) facebookID {
    return _facebookID;
}

+ (NSString*) facebookName {
    return _facebookName;
}

+ (void)createAccountFirst:(NSString*)first
                      last:(NSString*)last
                     email:(NSString*)email
                  facebook:(NSString*)facebookID
                  password:(NSString*)password
                completion:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) completion{
    // The account creation type is either a Facebook
    // type, or an email type.
    _facebookName = [first stringByAppendingString:[NSString stringWithFormat:@" %@", last]];
    NSString *account_type = @"facebook";
    BOOL isFacebook = YES;
    if (email) {
        account_type = @"email";
        isFacebook = NO;
    }
    
    if (isFacebook) {
        [IntertwineManager setAccountType:kAccountTypeFacebook];
    } else {
        [IntertwineManager setAccountType:kAccountTypeEmail];
    }
    
    // Build the request instance
    NSMutableURLRequest *request = [IntertwineManager getRequest:@"/api/v1/adduser"];
    [request setHTTPMethod:@"POST"];
    // Build the args for an email account
    NSString *args = nil;
    if (!isFacebook) {
        args = [NSString stringWithFormat:@"first=%@&last=%@&email=%@&password=%@&account_type=%@",
                first,
                last,
                email,
                password,
                account_type];
    } else if (isFacebook) {
        args = [NSString stringWithFormat:@"first=%@&last=%@&facebook_id=%@&account_type=%@",
                first,
                last,
                facebookID,
                account_type];
    }
    // Bail early if we haven't built any arguements.
    if (args == nil)
        return; //TODO: Raise an error
    // Set the request body
    NSData *requestBody = [args dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestBody];
    // Send the request asynchronously
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (![IntertwineManager isConnectionError:connectionError HTTPResponse:response data:data]) {
            NSError *err = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            if (json && !err) {
                NSString *serverError = [json objectForKey:@"error"];
                if ((NSNull*)serverError != [NSNull null]){
                    NSLog(@"Server Error: %@", serverError);
                }
                if(isFacebook) {
                    NSString *hashkey = [json objectForKey:@"session_key"];
                    NSNumber *accountIDNumber = [json objectForKey:@"account_id"];
                    NSString *accountid = [NSString stringWithFormat:@"%d", [accountIDNumber integerValue]];
                    [IntertwineManager setHashkey:hashkey];
                    [IntertwineManager setAccountID:accountid];
                }
                if (completion)
                    completion(response, data, connectionError);
                
            }
        } else {
            NSLog(@"We're in the bad part of town...");
            completion(nil, nil, nil);
        }
    }];
}

+ (void)emailSignOn:(NSString*)emailAddress
           password:(NSString*)password
         completion:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) completion {
    NSMutableURLRequest *request = [IntertwineManager getRequest:@"/api/v1/signin"];
    [request setHTTPMethod:@"POST"];
    NSString *args = [NSString stringWithFormat:@"email=%@&password=%@",
                      emailAddress,
                      password];
    NSData *requestBody = [args dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:requestBody];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (![IntertwineManager isConnectionError:connectionError HTTPResponse:response data:data]) {
            NSError *err = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            if (json && !err) {
                NSString *hashkey = [json objectForKey:@"hashkey"];
                NSString *accountid = [json objectForKey:@"accountid"];
                [IntertwineManager setHashkey:hashkey];
                [IntertwineManager setAccountID:accountid];
                [IntertwineManager setAccountType:kAccountTypeEmail];
            }
            completion(response, data, connectionError);
        }
    }];
}

+ (NSString*)accountIDFilePath {
    NSString *directoryPath = [IntertwineManager filePath];
    return [directoryPath stringByAppendingPathComponent:@"account_id.out"];
}

+ (NSString*)hashkeyFilePath {
    NSString *directoryPath = [IntertwineManager filePath];
    return [directoryPath stringByAppendingPathComponent:@"hashkey.out"];
}

+ (NSString*)getAccountID {
    if (_accountID) {
        return _accountID;
    }
    NSString *filePath = [IntertwineManager accountIDFilePath];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data)
        return nil;
    NSString *accountID = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [IntertwineManager setAccountID:accountID];
    return accountID;
}

+ (BOOL)setAccountID:(NSString*)accountID {
    if (!accountID)
        return NO;
    _accountID = accountID;
    // Write the new account ID to file, to save for relaunches
    NSString *filePath = [IntertwineManager accountIDFilePath];
    NSData *data = [accountID dataUsingEncoding:NSUTF8StringEncoding];
    return [data writeToFile:filePath atomically:YES];
}

+ (NSString*)getHash {
    if (_hashkey) {
        return _hashkey;
    }
    NSString *filePath = [IntertwineManager hashkeyFilePath];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data)
        return nil;
    NSString *hashkey = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [IntertwineManager setHashkey:hashkey];
    return hashkey;
}

+ (BOOL)setHashkey:(NSString*)hashkey {
    if (!hashkey)
        return NO;
    _hashkey = hashkey;
    // Write the new account ID to file, to save for relaunches
    NSString *filePath = [IntertwineManager hashkeyFilePath];
    NSData *data = [hashkey dataUsingEncoding:NSUTF8StringEncoding];
    return [data writeToFile:filePath atomically:YES];

}


+ (void)attachCredentialsToRequest:(NSMutableURLRequest*)request {
    NSString *accountID = [IntertwineManager getAccountID];
    NSString *sessionKey = [IntertwineManager getHash];

    if (accountID != nil){
        [request setValue:accountID forHTTPHeaderField:@"user_id"];
    }
    if (sessionKey != nil) {
        [request setValue:sessionKey forHTTPHeaderField:@"session_key"];
    }
}


+ (void)setAccountType:(AccountType)accountType {
    _accountType = accountType;
}

+ (AccountType)accountType {
    return _accountType;
}


#pragma mark - Device Token
+ (NSData*)getDeviceToken {
    return _deviceToken;
}
+ (void)setDeviceToken:(NSData*)deviceToken {
    _deviceToken = deviceToken;
}


+ (void) clearCredentialCache{
    [IntertwineManager setAccountID:@""];
    [IntertwineManager setHashkey:@""];
}


@end
