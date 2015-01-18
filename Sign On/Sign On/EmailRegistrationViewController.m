//
//  EmailRegistrationViewController.m
//  Sign On
//
//  Created by Ben Rooke on 11/28/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import "EmailRegistrationViewController.h"
#import "WebViewController.h"
#import "AppDelegate.h"
#import "IntertwineManager.h"

@interface EmailRegistrationViewController ()

@property (nonatomic, strong) NSMutableDictionary *errorLabels;

- (void)_resetEmailRegistrationFields;
- (BOOL)_handleErrors:(id)json;

- (void)_hideAllErrorLabels;
- (BOOL)_passwordsMatch;
- (BOOL)_isEmptyFields;

@end

const NSString *firstNameKey = @"first";
const NSString *lastNameKey = @"last";
const NSString *emailKey = @"email";
const NSString *passwordKey = @"password";

const NSString *tosString = @"http://test-intertwine.cloudapp.net/tos.html";
const float emailRegistrationAnimationDuration = 0.5;


@implementation EmailRegistrationViewController

#pragma mark - Handle Errors

- (BOOL)_handleErrors:(id)json {
    
    if ([json objectForKey:@"success"]) {
        return NO;
    }
    
    for (id key in json) {
        if ([self.errorLabels objectForKey:key]) {
            UILabel *errorLabel = [self.errorLabels objectForKey:key];
            errorLabel.text = json[key];
            errorLabel.hidden = NO;
        }
    }
    return YES;
}

- (void)_hideAllErrorLabels {
    for (id key in self.errorLabels) {
        [self.errorLabels[key] setHidden:YES];
    }
}

- (BOOL)_passwordsMatch {
    BOOL match = [self.registrationPasswordField.text isEqualToString:self.registrationRetypePasswordField.text];
    if (!match) {
        self.passwordErrorLabel.text = @"Passwords do not match";
        self.passwordErrorLabel.hidden = NO;
    }
    return match;
}

- (BOOL)_isEmptyFields {
    BOOL bailEarly = NO;
    
    if (self.registrationFirstNameField.text.length == 0) {
        self.firstNameErrorLabel.text = @"Enter a first name";
        self.firstNameErrorLabel.hidden = NO;
        bailEarly = YES;
    }
    if (self.registrationLastNameField.text.length == 0) {
        self.lastNameErrorLabel.text = @"Enter a last name";
        self.lastNameErrorLabel.hidden = NO;
        bailEarly = YES;
    }
    if (self.registrationEmailField.text.length == 0) {
        self.emailErrorLabel.text = @"Enter an email";
        self.emailErrorLabel.hidden = NO;
        bailEarly = YES;
    }
    if (self.registrationPasswordField.text.length == 0) {
        self.passwordErrorLabel.text = @"Enter a password";
        self.passwordErrorLabel.hidden = NO;
        bailEarly = YES;
    }

    return bailEarly;
}

#pragma mark - Terms of Service

- (IBAction)tos:(id)sender {
    NSURL *url = [NSURL URLWithString:(NSString*)tosString];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    WebViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"WebView"];
    vc.title = @"Terms of Service";
    vc.url = url;
    [self presentViewController:vc animated:YES completion:nil];
}


#pragma mark - Email registration

- (void)_resetEmailRegistrationFields {
    self.registrationFirstNameField.text = @"";
    self.registrationLastNameField.text = @"";
    self.registrationEmailField.text = @"";
    self.registrationPasswordField.text = @"";
}

- (IBAction)submitRegistration:(id)sender {
    
    [self _hideAllErrorLabels];
    
    if ([self _isEmptyFields]) {
        return;
    }
    
    if (![self _passwordsMatch]) {
        return;
    }
    
    NSString *first = self.registrationFirstNameField.text;
    NSString *last = self.registrationLastNameField.text;
    NSString *email = self.registrationEmailField.text;
    NSString *password = self.registrationPasswordField.text;
    
    [IntertwineManager createAccountFirst:first last:last email:email facebook:nil password:password completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data.length > 0 && connectionError == nil) {
            NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
            if (statusCode/100 != 2) {
                NSLog(@"Bad status code %ld", (long)statusCode);
            } else {
                // Now we can comfortably do something with the data returned
                // Let's try to convert it into JSON
                NSError *err = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
                if (json && !err) {
                    BOOL err = [self _handleErrors:json];
                    if (!err) {
                        [self dismissViewControllerAnimated:NO completion:nil];
                        [self.delegate signInWithEmail:self.registrationEmailField.text];
                    }
                }
            }
        } else if (connectionError) {
            NSLog(@"%@", connectionError);
        }
    }];

}


- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Text Field Did Change

- (void)_textFieldDidChange:(id)sender {
    NSString *text = [sender text];
    [(UITextField*)sender setText:text.capitalizedString];
}


#pragma mark - View Load

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.errorLabels = [[NSMutableDictionary alloc] init];
    self.errorLabels[firstNameKey] = self.firstNameErrorLabel;
    self.errorLabels[lastNameKey] = self.lastNameErrorLabel;
    self.errorLabels[emailKey] = self.emailErrorLabel;
    self.errorLabels[passwordKey] = self.passwordErrorLabel;

    // Hide all the error labels
    [self _hideAllErrorLabels];
    
    // Set up the captilization functions
    [self.registrationFirstNameField addTarget:self
                  action:@selector(_textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
    [self.registrationLastNameField addTarget:self
                  action:@selector(_textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
