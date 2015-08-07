//
//  IntertwineManager+Activity.h
//  Intertwine
//
//  Created by Ben Rooke on 4/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntertwineManager.h"

@interface IntertwineManager (Activity)

+ (void) getActivityFeedWithResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;

@end
