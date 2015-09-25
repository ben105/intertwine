//
//  IntertwineManager+ProfileImage.h
//  Intertwine
//
//  Created by Ben Rooke on 9/18/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IntertwineManager.h"

@interface IntertwineManager (ProfileImage)

+ (NSMutableDictionary*)cache;

+ (UIImage*)profileImage:(NSString*)profileID;
+ (void) cachedImage:(NSData*)image forProfileID:(NSString*)profileID;
@end
