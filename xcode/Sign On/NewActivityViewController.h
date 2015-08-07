//
//  NewActivityViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 3/21/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ActivityCreationDelegate <NSObject>
@required
- (void) closeEventCreation;
@end

@interface NewActivityViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) id<ActivityCreationDelegate> delegate;

@property (nonatomic, strong) UICollectionView *invitedCollectionView;
@property (nonatomic, strong) UICollectionView *uninvitedCollectionView;

/* With the title of the event being at the top of the view, there will be a 
 * member of the class here that represents the colored background of the toolbar.
 * Also note that when the user is first presented with this screen, they will
 * be prompted to enter the title. We might want to change the toolbar look,
 * when the user is typing for the text field. */
@property (nonatomic, strong) UIView *headerToolbar;
@property (nonatomic, strong) UITextField *titleField;

/* The friends array keeps track of the list of your friends. */
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSMutableArray *invitedFriends;
@property (nonatomic, strong) NSMutableArray *uninvitedFriends;


@end