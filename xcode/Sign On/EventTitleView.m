//
//  EventTitleView.m
//  Invite
//
//  Created by Ben Rooke on 12/31/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import "EventTitleView.h"


const CGFloat TitleViewLabelInset = 10.0;

const CGFloat EventTitleViewAlpha = 0.33;
const CGFloat EventTitleViewAlphaEditMode = 0.16;
const CGFloat EventTitleViewBackgroundColor = 193.0/255.0;


@implementation EventTitleView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:EventTitleViewBackgroundColor
                                               green:EventTitleViewBackgroundColor
                                                blue:EventTitleViewBackgroundColor
                                               alpha:EventTitleViewAlpha];
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 5.0;
        
        [self addSubview:self.placeholderLabel];
        [self addSubview:self.titleTextField];
    }
    return self;
}

#pragma mark - Editing

- (void)hideBorder:(BOOL)hide {
    if (hide) {
        self.layer.borderWidth = 0;
        self.backgroundColor = [UIColor colorWithRed:EventTitleViewBackgroundColor
                                               green:EventTitleViewBackgroundColor
                                                blue:EventTitleViewBackgroundColor
                                               alpha:EventTitleViewAlphaEditMode];
    } else {
        self.layer.borderWidth = 1.0;
        self.backgroundColor = [UIColor colorWithRed:EventTitleViewBackgroundColor
                                               green:EventTitleViewBackgroundColor
                                                blue:EventTitleViewBackgroundColor
                                               alpha:EventTitleViewAlpha];
    }
}

#pragma mark - Text Field Delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.titleTextField.text isEqualToString:@""]) {
        self.placeholderLabel.hidden = NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {    
    // We want to begin the next phase.
    [self.titleTextField resignFirstResponder];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(didEnterTitle:)]) {
        [self.delegate didEnterTitle:self.titleTextField.text];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.placeholderLabel.hidden = YES;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(willEditTitle)]) {
        [self.delegate willEditTitle];
    }
}

#pragma mark - Lazy Loading

- (UILabel*)placeholderLabel {
    if (!_placeholderLabel) {
        CGFloat width = CGRectGetWidth(self.frame) - TitleViewLabelInset * 2.0;
        CGFloat height = CGRectGetHeight(self.frame) - TitleViewLabelInset * 2.0;
        _placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(TitleViewLabelInset, TitleViewLabelInset, width, height)];
        _placeholderLabel.text = @"";
        _placeholderLabel.hidden = NO;
        _placeholderLabel.userInteractionEnabled = NO;
        _placeholderLabel.textAlignment = NSTextAlignmentCenter;
        _placeholderLabel.textColor = [UIColor whiteColor];
    }
    return _placeholderLabel;
}

- (UITextField*)titleTextField {
    if (!_titleTextField) {
        CGFloat width = CGRectGetWidth(self.frame) - TitleViewLabelInset * 2.0;
        CGFloat height = CGRectGetHeight(self.frame) - TitleViewLabelInset * 2.0;
        _titleTextField = [[UITextField alloc] initWithFrame:CGRectMake(TitleViewLabelInset, TitleViewLabelInset, width, height)];
        _titleTextField.text = @"";
//        [_titleTextField addTarget:self
//                            action:@selector(_textFieldDidChange)
//                  forControlEvents:UIControlEventEditingChanged];
        _titleTextField.delegate = self;
        _titleTextField.textAlignment = NSTextAlignmentCenter;
        _titleTextField.returnKeyType = UIReturnKeyNext;
        _titleTextField.textColor = [UIColor whiteColor];
        _titleTextField.font = [UIFont fontWithName:@"HelveticaNeue" size:32];
        _titleTextField.adjustsFontSizeToFitWidth = YES;
        _titleTextField.minimumFontSize = 12.0;
    }
    return _titleTextField;
}


@end
