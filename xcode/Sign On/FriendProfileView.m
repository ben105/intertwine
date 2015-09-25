//
//  FriendProfileView.m
//  Intertwine
//
//  Created by Ben Rooke on 9/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "FriendProfileView.h"
#import "IntertwineManager+ProfileImage.h"

@interface FriendProfileView ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation FriendProfileView

- (void)setProfileID:(NSString*)profileID {
    
    UIImage *profileImage = [IntertwineManager profileImage:profileID];
    if (profileImage == nil) {
        NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square", profileID];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:userImageURL]];
        [IntertwineManager cachedImage:data forProfileID:profileID];
        profileImage = [UIImage imageWithData:data];
    }
    self.imageView.image = profileImage;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.layer.borderColor = [[UIColor blackColor] CGColor];
        self.layer.cornerRadius = CGRectGetWidth(frame) / 2.0;
        self.layer.borderWidth = .5;
        [self addSubview:self.imageView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (UIImageView*)imageView {
    if (!_imageView) {
        CGRect selfFrame = self.frame;
        selfFrame.origin.x = 0;
        selfFrame.origin.y = 0;
        _imageView = [[UIImageView alloc] initWithFrame:selfFrame];
        _imageView.layer.cornerRadius = CGRectGetWidth(selfFrame) / 2.0;
    }
    return _imageView;
}

@end