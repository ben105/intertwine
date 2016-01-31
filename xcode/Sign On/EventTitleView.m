//
//  EventTitleView.m
//  Invite
//
//  Created by Ben Rooke on 12/31/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import "EventTitleView.h"


const CGFloat TitleViewLabelInset = 10.0;


@implementation EventTitleView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat color = 193.0/255.0;
        self.backgroundColor = [UIColor colorWithRed:color green:color blue:color alpha:0.33];
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 5.0;
        
        [self addSubview:self.placeholderLabel];
        [self addSubview:self.titleTextField];
    }
    return self;
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
    }
    return _titleTextField;
}


@end
