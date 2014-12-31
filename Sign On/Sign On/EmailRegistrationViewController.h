//
//  EmailRegistrationViewController.h
//  Sign On
//
//  Created by Ben Rooke on 11/28/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface EmailRegistrationViewController : UIViewController

@property (nonatomic, weak) IBOutlet UILabel *firstNameErrorLabel;
@property (nonatomic, weak) IBOutlet UILabel *lastNameErrorLabel;
@property (nonatomic, weak) IBOutlet UILabel *emailErrorLabel;
@property (nonatomic, weak) IBOutlet UILabel *passwordErrorLabel;

@property (nonatomic, weak) IBOutlet UITextField *registrationFirstNameField;
@property (nonatomic, weak) IBOutlet UITextField *registrationLastNameField;
@property (nonatomic, weak) IBOutlet UITextField *registrationEmailField;
@property (nonatomic, weak) IBOutlet UITextField *registrationPasswordField;
@property (nonatomic, weak) IBOutlet UITextField *registrationRetypePasswordField;

@property (nonatomic, weak) id<SignInDelegate> delegate;

- (IBAction)submitRegistration:(id)sender;

- (IBAction)cancel:(id)sender;

- (IBAction)tos:(id)sender;

@end
