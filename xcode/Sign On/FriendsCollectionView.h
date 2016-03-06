//
//  FriendsCollectionView.h
//  Invite
//
//  Created by Ben Rooke on 12/29/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Friend;
@class FriendsCollectionView;

typedef enum {
    kNotFound = 0,
    kNormal,
    kInvited,
    kDisabled
} FriendStatus;

@protocol FriendsCollectionViewDelegate <NSObject>
@optional
- (void)friendsCollectionView:(FriendsCollectionView*)collectionView didSelectFriend:(Friend*)intertwineFriend;
@end


@interface FriendsCollectionView : UIView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, readonly) CGFloat bubbleWidth;

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) NSMutableArray *friendsDataSource;

@property (nonatomic, weak) id<FriendsCollectionViewDelegate> delegate;

- (instancetype) initWithFrame:(CGRect)frame;

- (NSArray*)friends;

/* 
 * Adding friends:
 *  We allow the user of this class to add friends to the collection view,
 *  but not through the actual collection view object itself. 
 */
- (BOOL)addFriend:(Friend*)intertwineFriend;
- (BOOL)addFriends:(NSArray*)intertwineFriends;

/*
 * Setting friends:
 *  This method provides the convenient way to completely change the data
 *  source.
 */
- (BOOL)setFriends:(NSArray*)intertwineFriends;

/*
 * Removing friends:
 *  We allow the user of this class to remove friends registered in the
 *  collection view, but not through the actual collection view object itself.
 */
- (void)removeFriend:(Friend*)intertwineFriend;
- (void)removeFriends:(NSArray*)intertwineFriends;

/*
 * Setting status:
 *  This affects how the friend will be visibly displayed, as well as 
 *  changing the actual interface responses. For instance, if the friend object
 *  has a kNormal status, then when the end-user touches the friend it will
 *  invoke the invite method.
 */
- (void)setStatus:(FriendStatus)status forFriend:(Friend*)intertwineFriend;
- (FriendStatus)statusOfFriend:(Friend*)intertwineFriend;

@end
