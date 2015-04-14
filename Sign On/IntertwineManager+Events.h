//
//  IntertwineManager+Events.h
//  Sign On
//
//  Created by Ben Rooke on 3/24/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntertwineManager.h"

@interface IntertwineManager (Events)

+ (void) addComment:(NSString*)comment forEvent:(NSNumber*)eventNumber withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;

+ (void) createEvent:(NSString*)title withFriends:(NSArray*)friends withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;
+ (void) deleteEvent:(NSNumber*)eventID withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;
+ (void) getEventsWithResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;

@end
