//
//  EventTitleView.h
//  Invite
//
//  Created by Ben Rooke on 12/31/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EventTitleViewDelegate <NSObject>
@optional
- (void)willEditTitle;
- (void)didEnterTitle:(NSString*)title;
@end

@interface EventTitleView : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, weak) id<EventTitleViewDelegate> delegate;

/* For when we are or are not in edit mode. */
- (void)hideBorder:(BOOL)hide;
@end
