//
//  IntertwineManager+ProfileImage.m
//  Intertwine
//
//  Created by Ben Rooke on 9/18/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "IntertwineManager+ProfileImage.h"

NSMutableDictionary *profileImagesCache;


@implementation IntertwineManager (ProfileImage)

+ (NSMutableDictionary*)cache {
    if (!profileImagesCache) {
        profileImagesCache = [[NSMutableDictionary alloc] initWithCapacity:50];
    }
    return profileImagesCache;
}

+ (UIImage*)profileImage:(NSString*)profileID {
    
    NSData *data = [[IntertwineManager cache] objectForKey:profileID];
    if (data) {
        return [[UIImage alloc] initWithData:data];
    }
    return nil;
}

+ (void) cachedImage:(NSData*)image forProfileID:(NSString*)profileID {
    if (image == nil || profileID == nil || [profileID isEqualToString:@""]) {
        return;
    }
    [[IntertwineManager cache] setObject:image forKey:profileID];
}

@end
