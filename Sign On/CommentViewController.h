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

@property (nonatomic, weak) EventObject *event;

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;

@property (nonatomic, weak) IBOutlet UICollectionView *attendeesCollectionView;

- (IBAction)dismiss:(id)sender;

@end
