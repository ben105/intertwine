//
//  sadsad.h
//  Sign On
//
//  Created by Ben Rooke on 1/18/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntertwineManager.h"

@interface IntertwineManager (Friends)


/*
 * Get the list of valid Facebook friends
 */
+ (void) getFacebookFriends:(NSArray*)fbFriends withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;

/* 
 * Send a friend request
 */
+ (void) sendFriendRequest:(NSString*)friendAccountID response:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;

/*
 * Replying to a friend requests
 * (i.e. Accept of Decline).
 */
+ (void) acceptFriendRequest:(NSString*)friendAccountID response:(void (^)(id json, NSError *error, NSURLResponse *response)) responseBlock;
+ (void) declineFriendRequest:(NSString*)friendAccountID response:(void (^)(id json, NSError *error, NSURLResponse *response)) responseBlock;

/*
 * List of your current Intertwine friends.
 */
+ (void) friends:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock;

/*
 * List of friend suggestions, as derived from facebook friends who have
 * an Intertwine account, and are not already your friend, or blocked.
 */
+ (void) friendSuggestions:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock;

/*
 * Pending requests that should be acknowledged.
 */
+ (void) pendingRequest:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock;

/*
 * Search for any Intertwine accounts, that have not blocked you.
 */
+ (void) searchAccounts:(NSString*)entry response:(void (^)(id json, NSError *error, NSURLResponse *response)) responseBlock;

@end
