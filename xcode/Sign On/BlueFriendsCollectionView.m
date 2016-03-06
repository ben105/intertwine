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

const CGFloat BlueFriendsBackgroundAlpha = 0.33;
const CGFloat BlueFriendsBackgroundAlphaEditMode = 0.16;

const CGFloat BlueFriendsBackgroundColor = 193.0/255.0;

@interface BlueFriendsCollectionView ()
- (void) _enableEditButton;
- (void) _disableEditButton;
- (void)_delegateShouldEditEnable;
- (void)_delegateShouldEditDisable;
@end

@implementation BlueFriendsCollectionView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.collectionView.backgroundColor = [UIColor colorWithRed:BlueFriendsBackgroundColor
                                                              green:BlueFriendsBackgroundColor
                                                               blue:BlueFriendsBackgroundColor
                                                              alpha:BlueFriendsBackgroundAlpha];
        self.collectionView.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.collectionView.layer.borderWidth = 1.0;
        self.collectionView.layer.cornerRadius = 5.0;
        
        /* We will call this method to set up the right method initially. */
        [self _enableEditButton];
        
        /* But by default, this control is turned off. */
        self.editControl.enabled = NO;
    }
    return self;
}


#pragma mark - Editing

- (void)_delegateShouldEditEnable {
    if (![self.editControl isEnabled]) {
        return;
    }
    if ([self.bluesDelegate respondsToSelector:@selector(shouldEnableEditCollectionView)]) {
        [self.bluesDelegate shouldEnableEditCollectionView];
    }
}

- (void)_delegateShouldEditDisable {
    if (![self.editControl isEnabled]) {
        return;
    }
    if ([self.bluesDelegate respondsToSelector:@selector(shouldDisableEditCollectionView)]) {
        [self.bluesDelegate shouldDisableEditCollectionView];
    }
}

- (void) _enableEditButton {
//    CGFloat width = CGRectGetWidth(self.collectionView.frame);
//    CGFloat height = CGRectGetHeight(self.collectionView.frame);
//    self.editControl.frame = CGRectMake(0, 0, width, height);
//    if (self.editControl.superview != nil) {
//        [self.editControl removeFromSuperview];
//    }
//    [self.collectionView addSubview:self.editControl];
    [self.editControl removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.editControl addTarget:self action:@selector(_delegateShouldEditEnable) forControlEvents:UIControlEventTouchUpInside];
}

- (void) _disableEditButton {
//    [self.editControl removeFromSuperview];
    [self.editControl removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.editControl addTarget:self action:@selector(_delegateShouldEditDisable) forControlEvents:UIControlEventTouchUpInside];
}

- (void)editMode:(BOOL)edit {
    if (edit) {
        self.collectionView.layer.borderWidth = 0;
        self.titleBar.hidden = YES;
        self.collectionView.backgroundColor = [UIColor colorWithRed:BlueFriendsBackgroundColor
                                                              green:BlueFriendsBackgroundColor
                                                               blue:BlueFriendsBackgroundColor
                                                              alpha:BlueFriendsBackgroundAlphaEditMode];
        [self _enableEditButton];
    } else {
        self.collectionView.layer.borderWidth = 1.0;
        self.titleBar.hidden = NO;
        self.collectionView.backgroundColor = [UIColor colorWithRed:BlueFriendsBackgroundColor
                                                              green:BlueFriendsBackgroundColor
                                                               blue:BlueFriendsBackgroundColor
                                                              alpha:BlueFriendsBackgroundAlpha];
        [self _disableEditButton];
    }
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


#pragma mark - Setting the Frame

- (void)setCollectionViewFrame:(CGRect)frame {
    self.frame = frame;
    CGRect collectionViewFrame = frame;
    collectionViewFrame.origin.x = 0;
    collectionViewFrame.origin.y = 0;
    self.collectionView.frame = collectionViewFrame;
}


#pragma mark - Lazy Loading

- (UIControl*)editControl {
    if (!_editControl) {
        /* Note that the rect will actually be set when the control is enabled. */
        CGFloat width = CGRectGetWidth(self.collectionView.frame);
        CGFloat height = CGRectGetHeight(self.collectionView.frame);
        _editControl = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        [_editControl addTarget:self action:@selector(_delegateShouldEditEnable) forControlEvents:UIControlEventTouchUpInside];
        self.collectionView.backgroundView = _editControl;
    }
    return _editControl;
}

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
