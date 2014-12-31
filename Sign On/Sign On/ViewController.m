//
//  ViewController.m
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import "ViewController.h"
#import "EmailRegistrationViewController.h"

const float emailSignInAnimationDuration = 0.5;

NSString *newsfeedStoryboardID = @"Newsfeed";



@interface ViewController ()

- (void)_presentEmailSignInView:(BOOL)animated;
- (void)_resetEmailSignInFields;

- (void)_presentView:(UIView*)aView animationSpeed:(float)speed animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)_dismissView:(UIView*)aView animationSpeed:(float)speed animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)_toggleView:(UIView*)aView animationSpeed:(float)speed animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)_viewAlpha:(float)alpha view:(UIView*)aView animationSpeed:(float)speed animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (void) _signOnAlert:(NSString*)msg ;

@end

@implementation ViewController

#pragma mark - Authenticate

#pragma mark - Facebook Login

- (IBAction)faceookLogin:(id)sender {
    NSLog(@"Facebook login clicked");
}


#pragma mark - Email Login

- (IBAction)presentEmailSignIn:(id)sender {
    [self _presentEmailSignInView:YES];
}

- (IBAction)dismissEmailSignIn:(id)sender {
    [self _dismissEmailSignInView:YES];
}

- (void)_presentEmailSignInView:(BOOL)animated {
    [self.view bringSubviewToFront:self.emailSignInView];
    [self _presentView:self.emailSignInView animationSpeed:emailSignInAnimationDuration animated:animated completion:nil];
}

- (void)_dismissEmailSignInView:(BOOL)animated {
    [self _dismissView:self.emailSignInView animationSpeed:emailSignInAnimationDuration animated:animated completion:^(BOOL finished) {
        [self _resetEmailSignInFields];
    }];
}

- (void)_resetEmailSignInFields {
    self.signInEmailAddressField.text = @"";
    self.signInPasswordField.text = @"";
}

#pragma mark - Sign On

- (void) _signOnAlert:(NSString*)msg {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"Okay"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)signOn:(id)sender {
    if ([self.signInEmailAddressField.text length]==0 || [self.signInPasswordField.text length]==0) {
        [self _signOnAlert:@"Missing information."];
    }
}

#pragma mark - Sign Up

- (IBAction)signUp:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EmailRegistrationViewController *registrationVC = [storyboard instantiateViewControllerWithIdentifier:@"EmailRegistration"];
    registrationVC.delegate = self;
    [self presentViewController:registrationVC animated:YES completion:nil];
}

#pragma mark - View Load

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _dismissEmailSignInView:NO];
    // Do any additional setup after loading the view, typically from a nib.
}


#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Sign In Delegate

- (void)signInWithEmail:(NSString*)email {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Newsfeed"];
    [self presentViewController:vc animated:YES completion:nil];
}


#pragma mark - Generic Present View

- (void)_presentView:(UIView*)aView animationSpeed:(float)speed animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    [self _viewAlpha:1 view:aView animationSpeed:speed animated:animated completion:completion];
}

- (void)_dismissView:(UIView*)aView animationSpeed:(float)speed animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    [self _viewAlpha:0 view:aView animationSpeed:speed animated:animated completion:completion];
}

- (void)_toggleView:(UIView*)aView animationSpeed:(float)speed animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    [self _viewAlpha:!aView.alpha view:aView animationSpeed:speed animated:animated completion:completion];
}

- (void)_viewAlpha:(float)alpha view:(UIView*)aView animationSpeed:(float)speed animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    if (animated) {
        [UIView animateWithDuration:speed
                         animations:^{
                             aView.alpha = alpha;
                         }
                         completion:completion];
    } else {
        aView.alpha = alpha;
        completion(YES);
    }
}


@end
