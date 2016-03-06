//
//  BlueFriendsCollectionView.h
//  Invite
//
//  Created by Ben Rooke on 12/29/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import "FriendsCollectionView.h"

@protocol BlueFriendsDelegate <NSObject>
@optional
- (void)shouldEnableEditCollectionView;
- (void)shouldDisableEditCollectionView;
@end

@interface BlueFriendsCollectionView : FriendsCollectionView

/* The following two properties are for controllers that wish to edit 
 * the views and contents. */
@property (nonatomic, strong) UIControl *editControl;
@property (nonatomic, weak) id<BlueFriendsDelegate> bluesDelegate;

@property (nonatomic, copy) NSString *title;
- (void)removeTitle;
- (void)editMode:(BOOL)edit;
- (void)setCollectionViewFrame:(CGRect)frame;
@end
