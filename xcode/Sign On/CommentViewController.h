//
//  CommentViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 4/11/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventObject;

@interface CommentViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) EventObject *event;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;

@property (nonatomic, strong) UIControl *dismissControlView;
@property (nonatomic, weak) IBOutlet UITextField *commentTextField;

@property (nonatomic, weak) IBOutlet UICollectionView *attendeesCollectionView;

// The data model for all the comments
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, weak) IBOutlet UITableView *commentsTableView;

- (IBAction)dismiss:(id)sender;

- (IBAction) postComment ;

@end


