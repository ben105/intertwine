//
//  NewEventViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 3/21/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EventCreationDelegate <NSObject>
@required
- (void) closeEventCreation;
@end

@interface NewEventViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) id<EventCreationDelegate> delegate;

@property (nonatomic, weak) IBOutlet UICollectionView *invitedCollectionView;
@property (nonatomic, weak) IBOutlet UICollectionView *uninvitedCollectionView;

@property (nonatomic, weak) IBOutlet UITextField *titleField;

/* The friends array keeps track of the list of your friends. */
@property (nonatomic, strong) NSArray *friends;


@property (nonatomic, strong) NSMutableArray *invitedFriends;
@property (nonatomic, strong) NSMutableArray *uninvitedFriends;

- (IBAction)cancel:(id)sender;
- (IBAction)create:(id)sender;

- (IBAction)dismissKeyboard:(id)sender;

@end
