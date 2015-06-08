//
//  ITAddView.h
//  Dynamic Banner
//
//  Created by Ben Rooke on 5/23/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    AddEvent = 0,
    CategoryEvent,
    RandomEvent
} AddViewSelection;


/* Protocol for those who wish to be a delegate
 * for this class. */
@protocol ITAddViewDelegate <NSObject>
@optional
-(void)willExpand;
-(void)willCollapse;
-(void)fingerOverSelection:(AddViewSelection)selection;
-(void)fingerOffSelection;

-(void)didMakeSelection:(AddViewSelection)selection;

@end


@interface ITAddView : UIView

@property (nonatomic, assign) id<ITAddViewDelegate> delegate;

/* Helper method to get string version of enum. */
+ (NSString*)selectionDescription:(AddViewSelection)selection;

/* Expanding to more refined selections. */
@property BOOL isExpanded;
- (void) expandAnimated:(BOOL)animated;
- (void) collapseAnimated:(BOOL)animated;

@end

extern const CGFloat addViewWidth;
extern const CGFloat addViewHeight;
extern const CGFloat AddViewAnimationDuration;