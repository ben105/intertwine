//
//  IntertwineManager.m
//  Sign On
//
//  Created by Ben Rooke on 1/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "IntertwineManager.h"

@interface IntertwineManager ()

+(BOOL) checkConnectionError:(NSError*)error HTTPResponse:(NSURLResponse*)response data:(NSData*)data;

@end

@implementation IntertwineManager

NSString *_accountID = nil;
NSString *_hashkey = nil;
const NSString *server = @"http://test-intertwine.cloudapp.net:5000";



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
//    NSString *user_id = [IntertwineManager getAccountID];
//    if (user_id) {
//        NSString *params = [NSString stringWithFormat:@"user_id=%@", user_id];
//        NSData *body = [params dataUsingEncoding:NSUTF8StringEncoding];
//        [request setHTTPBody:body];
//    }
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
                                   if (data && [data length]) {
                                       NSError *jsonReadingError = nil;
                                       id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonReadingError];
                                       if (jsonReadingError) {
                                           responseBlock(nil, jsonReadingError, response);
                                       } else {
                                           responseBlock(json, nil, response);
                                       }
                                   } else {
                                       responseBlock(nil, nil, response);
                                   }
                               }
                           }];
}



#pragma mark - Account Management

+ (void)createAccountFirst:(NSString*)first
                      last:(NSString*)last
                     email:(NSString*)email
                  facebook:(NSString*)facebookID
                  password:(NSString*)password
                completion:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError)) completion{
    // The account creation type is either a Facebook
    // type, or an email type.
    NSString *account_type = @"facebook";
    BOOL isFacebook = YES;
    if (email) {
        account_type = @"email";
        isFacebook = NO;
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
                NSLog(@"%@",json);
                if(isFacebook) {
                    NSString *hashkey = [json objectForKey:@"session_key"];
                    NSString *accountid = [json objectForKey:@"account_id"];
                    [IntertwineManager setHashkey:hashkey];
                    [IntertwineManager setAccountID:accountid];
                }
                completion(response, data, connectionError);
            }
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
    NSLog(@"File path: %@", filePath);
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
    NSLog(@"Hash Key: %@", filePath);
    NSData *data = [hashkey dataUsingEncoding:NSUTF8StringEncoding];
    return [data writeToFile:filePath atomically:YES];

}


@end
