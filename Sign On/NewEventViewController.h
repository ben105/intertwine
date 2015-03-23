//
//  NewEventViewController.h
//  Sign On
//
//  Created by Ben Rooke on 3/21/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewEventViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) NSArray *friends;

@property (nonatomic, strong) NSMutableArray *invitedFriends;
@property (nonatomic, strong) NSMutableArray *uninvitedFriends;

@end
