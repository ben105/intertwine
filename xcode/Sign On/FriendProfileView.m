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
    _profileID = profileID;
    dispatch_queue_t queue = dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        UIImage *profileImage = [IntertwineManager profileImage:profileID];
        if (profileImage == nil) {
            NSString *userImageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", profileID];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:userImageURL]];
            [IntertwineManager cachedImage:data forProfileID:profileID];
            profileImage = [UIImage imageWithData:data];
        }
        /* Update the UI on the main thread. */
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.imageView.image = profileImage;
        });
    });
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.layer.cornerRadius = CGRectGetWidth(frame) / 2.0;
        self.layer.borderWidth = 1.0;
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowOffset = CGSizeMake(0, 6);
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
