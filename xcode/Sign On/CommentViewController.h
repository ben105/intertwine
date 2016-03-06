//
//  CommentViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 4/11/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventObject;

@protocol CommentViewDelegate <NSObject>
@optional
- (void)didEnterCommentMode;
- (void)didExitCommentMode;
- (void)shouldDismissCommentView;
@end

@interface CommentViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<CommentViewDelegate> delegate;
@property (nonatomic, strong) EventObject *event;
@property (nonatomic, strong) UILabel *titleLabel;
//@property (nonatomic, weak) UITextView *descriptionTextView;
@property (nonatomic, strong) UITextField *commentTextField;
//@property (nonatomic, weak) UICollectionView *attendeesCollectionView;
// The data model for all the comments
@property (nonatomic, strong) NSMutableArray *comments;

- (void)postComment;

//- (IBAction)markCompleted:(id)sender;

@end


