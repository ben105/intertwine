//
//  IntertwineManager+Friends.m
//  Sign On
//
//  Created by Ben Rooke on 1/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "IntertwineManager.h"

@implementation IntertwineManager (Friends)

const NSString *acceptRequest = @"/api/v1/friend_accept";
const NSString *declineRequest = @"/api/v1/friend_decline";
const NSString *friendsRequest = @"/api/v1/friends";
const NSString *suggestionsRequest = @"";
const NSString *pendingRequest = @"/api/v1/friend_requests";
const NSString *searchRequest = @"/api/v1/search";
const NSString *facebookFriends = @"/api/v1/facebook_friends";

#pragma mark - Sending a Request

+ (void) getFacebookFriends:(NSArray*)fbFriends withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)facebookFriends];
    [request setHTTPMethod:@"POST"];
    NSError *error = nil;
    NSData* json = [NSJSONSerialization dataWithJSONObject:[NSArray arrayWithArray:fbFriends] options:0 error:&error];
    if (error) {
        NSLog(@"An error occurred trying to convert list of Facebook IDs to a JSON object: %@", error);
    }
    [request setHTTPBody:json];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [IntertwineManager sendRequest:request response:responseBlock];
}

+ (void) sendFriendRequest:(NSString*)friendAccountID response:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)pendingRequest];
    [request setHTTPMethod:@"POST"];
    NSString *bodyString = [NSString stringWithFormat:@"friend_id=%@",friendAccountID];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];
    [IntertwineManager sendRequest:request response:responseBlock];
}


#pragma mark - Accept/Decline Requests

+ (void) acceptFriendRequest:(NSString*)friendAccountID response:(void (^)(id json, NSError *error, NSURLResponse *response)) responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)acceptRequest];
    [request setHTTPMethod:@"POST"];
    NSString *bodyString = [NSString stringWithFormat:@"friend_id=%@",friendAccountID];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];
    [IntertwineManager sendRequest:request response:responseBlock];
}

+ (void) declineFriendRequest:(NSString*)friendAccountID response:(void (^)(id json, NSError *error, NSURLResponse *response)) responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)declineRequest];
    [request setHTTPMethod:@"POST"];
    NSString *bodyString = [NSString stringWithFormat:@"friend_id=%@",friendAccountID];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];
    [IntertwineManager sendRequest:request response:responseBlock];
}


#pragma mark - List of Friends

+ (void) friends:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)friendsRequest];
    [request setHTTPMethod:@"POST"];
    [IntertwineManager sendRequest:request response:responseBlock];
}

#pragma mark - Friend Suggestions

+ (void) friendSuggestions:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)suggestionsRequest];
    [IntertwineManager sendRequest:request response:responseBlock];
}

#pragma mark - Pending Requests

+ (void) pendingRequest:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)pendingRequest];
    [IntertwineManager sendRequest:request response:responseBlock];
}

#pragma mark - Search for Intertwine Account

+ (void) searchAccounts:(NSString*)entry response:(void (^)(id json, NSError *error, NSURLResponse *response)) responseBlock {
    NSString *apiPath = [(NSString*)searchRequest stringByAppendingPathComponent:entry];
    NSMutableURLRequest *request = [IntertwineManager getRequest:apiPath];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    [IntertwineManager sendRequest:request response:responseBlock];
}



@end
