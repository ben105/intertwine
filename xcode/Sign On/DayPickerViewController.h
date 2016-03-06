//
//  DayPickerViewController.h
//  DatePicker
//
//  Created by Ben Rooke on 1/18/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideToChooseTableViewCell.h"
#import "SemesterView.h"

@class SemesterPage;

@protocol DayPickerDelegate <NSObject>
@optional
- (void) shouldDismissDayPickerViewController;
@required
- (void) didSelectStartDate:(nonnull NSString*)startDate semesterIndex:(NSUInteger)semesterIndex;
@end

@interface DayPickerViewController : UIViewController <UITableViewDataSource, UIScrollViewDelegate, UITableViewDelegate, SlideToChooseTableViewCellDelegate, SemesterViewDelegate>

/* Table view to pick the day. */
@property (nonatomic, strong) UITableView *dayPickerTableView;

/* Semester view to pick the part of day. */
@property (nonatomic, strong) SemesterPage *semesterPickerView;

/* A view to pick the time of day. */
@property (nonatomic, strong) UIView *timePickerView;

@property (nonatomic, weak) id<DayPickerDelegate> delegate;

@end