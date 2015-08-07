//
//  Friend.m
//  Sign On
//
//  Created by Ben Rooke on 3/23/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "Friend.h"

@implementation Friend

- (NSString*) fullName {
    return [self.first stringByAppendingString:[NSString stringWithFormat:@" %@",self.last]];
}

@end
