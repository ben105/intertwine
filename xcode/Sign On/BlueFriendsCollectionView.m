//
//  BlueFriendsCollectionView.m
//  Invite
//
//  Created by Ben Rooke on 12/29/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import "BlueFriendsCollectionView.h"

@interface BlueFriendsCollectionView ()
@property (nonatomic, strong) UIView *titleBar;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation BlueFriendsCollectionView

- (instancetype) initWithFrame:(CGRect)frame andBubbleWidth:(CGFloat)bubbleWidth {
    self = [super initWithFrame:frame andBubbleWidth:bubbleWidth];
    if (self) {
        CGFloat colorValue = 193.0/255.0;
        CGFloat alpha = 0.33;
        self.collectionView.backgroundColor = [UIColor colorWithRed:colorValue green:colorValue blue:colorValue alpha:alpha];
        self.collectionView.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.collectionView.layer.borderWidth = 1.0;
        self.collectionView.layer.cornerRadius = 5.0;
    }
    return self;
}


#pragma mark - Setting Title

- (void)setTitle:(NSString *)title {
    _title = title;
    
    [self addSubview:self.titleBar];
    self.titleLabel.text = title;
}

- (void)removeTitle {
    [_titleBar removeFromSuperview];
    _titleBar = nil;
    _titleLabel = nil;
}


#pragma mark - Lazy Loading

- (UILabel*)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 25)];
        _titleLabel.center = CGPointMake(CGRectGetWidth(self.titleBar.frame)/2.0, CGRectGetHeight(self.titleBar.frame)/2.0);
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    }
    return _titleLabel;
}

- (UIView*)titleBar {
    if (!_titleBar) {
        _titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 25)];
        _titleBar.center = CGPointMake(CGRectGetWidth(self.frame)/2.0, 0);
        _titleBar.backgroundColor = [UIColor colorWithRed:65.0/255.0 green:97.0/255.0 blue:128.0/255.0 alpha:1];
        _titleBar.layer.borderColor = [[UIColor whiteColor] CGColor];
        _titleBar.layer.borderWidth = 1.0;
        _titleBar.layer.cornerRadius = 5.0;
        [_titleBar addSubview:self.titleLabel];
    }
    return _titleBar;
}

@end
