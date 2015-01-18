//
//  IntertwineManager+Friends.m
//  Sign On
//
//  Created by Ben Rooke on 1/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "IntertwineManager.h"

@implementation IntertwineManager (Friends)

const NSString *friendsRequest = @"/api/v1/friends";
const NSString *suggestionsRequest = @"";
const NSString *pendingRequest = @"/api/v1/friendrequests";



+ (void) friends:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:friendsRequest];
    [request setHTTPMethod:@"POST"];
    
    [IntertwineManager sendRequest:request response:responseBlock];
}

+ (void) friendSuggestions:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:suggestionsRequest];
    [IntertwineManager sendRequest:request response:responseBlock];
}

+ (void) pendingRequest:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:pendingRequest];
    [IntertwineManager sendRequest:request response:responseBlock];
}
@end
