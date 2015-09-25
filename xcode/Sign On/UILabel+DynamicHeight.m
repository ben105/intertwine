//
//  UILabel+DynamicHeight.m
//  CommentsViewController
//
//  Created by Ben Rooke on 6/20/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import "UILabel+DynamicHeight.h"


@implementation UILabel (UILabel_DynamicHeight)

- (CGSize) sizeOfMultiLineLabel {
    
    NSAssert(self, @"UILabel was nil");
    
    CGFloat width = CGRectGetWidth(self.frame);
    
    return [self.text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{ NSFontAttributeName: self.font }
                                   context:nil].size;
}


@end
