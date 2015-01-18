//
//  IntertwineManager.m
//  Sign On
//
//  Created by Ben Rooke on 1/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "IntertwineManager.h"


@implementation IntertwineManager

NSString *_accountID;
const NSString *server = @"http://test-intertwine.cloudapp.net:5000";

+ (NSString*)filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

#pragma mark - HTTP Requests

+ (NSMutableURLRequest*)getRequest {
    return [IntertwineManager getRequest:@""];
}

+ (NSMutableURLRequest*)getRequest:(NSString*)endpoint {
    NSString *urlString = [server stringByAppendingString:endpoint];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSString *user_id = [IntertwineManager getAccountID];
    if (user_id) {
        NSString *params = [NSString stringWithFormat:@"user_id=%@", user_id];
        NSData *body = [params dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:body];
    }
    return request;
}

// TODO: CLean this up!
+ (void)sendRequest:(NSMutableURLRequest*)request response:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock {
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError)
                                   responseBlock(nil, connectionError, response);
                               else {
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
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:completion];
}

+ (NSString*)accountIDFilePath {
    NSString *directoryPath = [IntertwineManager filePath];
    return [directoryPath stringByAppendingPathComponent:@"account_id.out"];
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

@end
