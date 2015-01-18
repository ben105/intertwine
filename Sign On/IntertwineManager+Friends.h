//
//  sadsad.h
//  Sign On
//
//  Created by Ben Rooke on 1/18/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IntertwineManager (Friends)

+ (void) friends:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock;

+ (void) friendSuggestions:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock;

+ (void) pendingRequest:(void (^)(id json, NSError* error, NSURLResponse *response))responseBlock;

@end
