//
//  BlueFriendsCollectionView.h
//  Invite
//
//  Created by Ben Rooke on 12/29/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import "FriendsCollectionView.h"

@interface BlueFriendsCollectionView : FriendsCollectionView

@property (nonatomic, copy) NSString *title;

- (void)removeTitle;

@end
