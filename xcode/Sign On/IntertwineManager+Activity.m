//
//  IntertwineManager+Activity.m
//  Intertwine
//
//  Created by Ben Rooke on 4/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "IntertwineManager+Activity.h"

const NSString *getActivityRequest = @"/api/v1/activity";
const NSString *getNotificationsRequest = @"/api/v1/notifications";

@implementation IntertwineManager (Activity)

+ (void) getActivityFeedWithResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)getActivityRequest];
    [IntertwineManager sendRequest:request response:responseBlock];
}


+ (void) getNotificationsWithResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)getNotificationsRequest];
    [IntertwineManager sendRequest:request response:responseBlock];
}

@end
