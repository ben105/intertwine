//
//  FriendsCollectionView.m
//  Invite
//
//  Created by Ben Rooke on 12/29/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import "FriendsCollectionView.h"
#import "EventCollectionViewCell.h"
#import "FriendProfileView.h"
#import "Friend.h"

#pragma mark - Collection Object

@interface CollectionObject : NSObject
@property (nonatomic, strong) Friend *intertwineFriend;
@property (nonatomic) FriendStatus status;
@end

@implementation CollectionObject
@end


#pragma mark - Global Variables

/* When adding a new friend to the data source, we set the default status. */
FriendStatus DEFAULT_STATUS = kNormal;
const NSString *kCollectionIdentifier = @"collection_cell";
const CGFloat collectionCellInteritemSpacing = 10.0;
const CGFloat collectionCellLineSpacing = 20.0;


#pragma mark - Friends Collection View Private Interface

@interface FriendsCollectionView ()
@property (nonatomic, strong) NSMutableDictionary *collectionDictionary;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewLayout;
- (BOOL)_validateFriend:(Friend*)intertwineFriend;
- (NSMutableArray*) _sortArray:(NSMutableArray*)unsortedArray;
- (CollectionObject*)_friendToCollectionObject:(Friend*)intertwineFriend;
@end




@implementation FriendsCollectionView

#pragma mark - Sorting

- (NSMutableArray*) _sortArray:(NSMutableArray*)unsortedArray {
    NSString *sortAttribute = @"intertwineFriend.first";
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:sortAttribute ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray* sortedArray = [unsortedArray sortedArrayUsingDescriptors:@[sort]];
    NSMutableArray *sortedMutableArray = [[NSMutableArray alloc] initWithArray:sortedArray];
    return sortedMutableArray;
}

#pragma mark - Conversion

- (CollectionObject*)_friendToCollectionObject:(Friend*)intertwineFriend {
    NSValue *value = [self.collectionDictionary objectForKey:intertwineFriend.accountID];
    return (CollectionObject*)[value pointerValue];
}

#pragma mark - Initialization

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _friendsDataSource = [NSMutableArray new];
        
        [self addSubview:self.collectionView];
    }
    return self;
}

- (BOOL)_validateFriend:(id)intertwineFriend {
    /* We want to check that the object the user of this class is trying to
     * add to the data source is actually a Friend object. */
    if (![intertwineFriend respondsToSelector:@selector(isKindOfClass:)] ||
        ![intertwineFriend isKindOfClass:[Friend class]]) {
        return NO;
    }
    
    /* To validate the Friend object, we want to make sure it has at least
     * one of the following:
       1) A first name.
       2) An email address OR a Facebook ID.
       3) An Intertwine account ID.
     */
    if (![intertwineFriend first] ||
        ![[intertwineFriend first] stringByReplacingOccurrencesOfString:@" " withString:@""]) {
        return NO;
    }
    if (![intertwineFriend emailAddress] && ![intertwineFriend facebookID]) {
        return NO;
    }
    if (![intertwineFriend accountID]) {
        return NO;
    }
    
    /* Finally, we want to check if the friend isn't already in the data source. */
    CollectionObject *c = [self _friendToCollectionObject:intertwineFriend];
    if (c != nil) {
        return NO;
    }
    
    return YES;
}

- (NSArray*)friends {
    NSMutableArray *m = [[NSMutableArray alloc] initWithCapacity:[self.friendsDataSource count]];
    for (CollectionObject *c in self.friendsDataSource) {
        [m addObject:c.intertwineFriend];
    }
    return m;
}

- (BOOL)addFriend:(Friend*)intertwineFriend {
    if (![self _validateFriend:intertwineFriend]) {
        return NO;
    }
    CollectionObject *collectionObject = [[CollectionObject alloc] init];
    collectionObject.intertwineFriend = intertwineFriend;
    collectionObject.status = DEFAULT_STATUS;
    
    /* I want to keep track of the collection object, so that we can quickly find it in the
     * array later. */
    [self.collectionDictionary setObject:[NSValue valueWithPointer:(__bridge const void *)collectionObject] forKey:intertwineFriend.accountID];
    
    [_friendsDataSource addObject:collectionObject];
    _friendsDataSource = [self _sortArray:_friendsDataSource];
    
    [self.collectionView reloadData];
    
    return YES;
}

- (BOOL)addFriends:(NSArray*)intertwineFriends {
    for (id intertwineFriend in intertwineFriends) {
        BOOL success = [self addFriend:intertwineFriend];
        if (!success) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)setFriends:(NSArray*)intertwineFriends {
    /* Save the state of the current data source. */
    NSMutableArray *tmpDataSource = self.friendsDataSource;
    NSUInteger capacity = [intertwineFriends count];
    _friendsDataSource = [[NSMutableArray alloc] initWithCapacity:capacity];
    BOOL success = [self addFriends:intertwineFriends];
    if (!success) {
        /* If not successful, rewind back. */
        _friendsDataSource = tmpDataSource;
        return NO;
    }
    return YES;
}

- (void)removeFriend:(Friend*)intertwineFriend {
    CollectionObject *collectionObject = [self _friendToCollectionObject:intertwineFriend];
    if (collectionObject == nil) {
        return;
    }
    [_friendsDataSource removeObject:collectionObject];
    [self.collectionDictionary removeObjectForKey:intertwineFriend.accountID];
    [self.collectionView reloadData];
}

- (void)removeFriends:(NSArray*)intertwineFriends {
    for (id intertwineFriend in intertwineFriends) {
        BOOL isFriendObject = [self _validateFriend:intertwineFriend];
        if (isFriendObject) {
            [self removeFriend:intertwineFriend];
        }
    }
}

- (void)setStatus:(FriendStatus)status forFriend:(Friend*)intertwineFriend {
    CollectionObject *collectionObject = [self _friendToCollectionObject:intertwineFriend];
    if (collectionObject == nil) {
        return;
    }
    collectionObject.status = status;
    [self.collectionView reloadData];
}

- (FriendStatus)statusOfFriend:(Friend*)intertwineFriend {
    CollectionObject *collectionObject = [self _friendToCollectionObject:intertwineFriend];
    return collectionObject.status;
}

#pragma mark - Lazy Loading

- (NSMutableDictionary*)collectionDictionary {
    if (!_collectionDictionary) {
        _collectionDictionary = [[NSMutableDictionary alloc] init];
    }
    return _collectionDictionary;
}

- (UICollectionViewFlowLayout*) collectionViewLayout {
    if (!_collectionViewLayout) {
        _collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        [_collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        [_collectionViewLayout setMinimumInteritemSpacing:collectionCellInteritemSpacing];
        [_collectionViewLayout setMinimumLineSpacing:collectionCellLineSpacing];
        [_collectionViewLayout setItemSize:CGSizeMake([EventCollectionViewCell cellWidth], [EventCollectionViewCell cellHeight])];
    }
    return _collectionViewLayout;
}

- (UICollectionView*)collectionView {
    if (!_collectionView) {
        CGRect frame = self.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:self.collectionViewLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        
        [_collectionView registerClass:[EventCollectionViewCell class]
            forCellWithReuseIdentifier:(NSString*)kCollectionIdentifier];

    }
    return _collectionView;
}




#pragma mark - UICollectionView Data Source


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.friendsDataSource count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // Attempt to get the event collection cell.
    EventCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(NSString*)kCollectionIdentifier forIndexPath:indexPath];
    
    // Get the account's Facebook ID.
    CollectionObject *collectionObject = [self.friendsDataSource objectAtIndex:indexPath.row];
    NSString *profileID = [collectionObject.intertwineFriend facebookID];
    if ((NSNull*)profileID == [NSNull null]) {
        profileID = @"0";
    }
    
    // Set the picture and name.
    cell.profilePicture.profileID = profileID;
    cell.nameLabel.text = [collectionObject.intertwineFriend first];
    
    if (collectionObject.status == kInvited) {
        cell.alpha = 0.3;
    } else if (collectionObject.status == kNormal) {
        cell.alpha = 1.0;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(0, 20.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    CGFloat edge = 15.0;
    return UIEdgeInsetsMake(edge, edge * 2.0, edge, edge * 2.0);
}

# pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(friendsCollectionView:didSelectFriend:)]) {
        Friend *f = [[self.friendsDataSource objectAtIndex:indexPath.row] intertwineFriend];
        [self.delegate friendsCollectionView:self didSelectFriend:f];
    }
}


@end
