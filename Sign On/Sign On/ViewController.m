//
//  ViewController.m
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import "ViewController.h"
#import "EmailRegistrationViewController.h"
#import "FriendsViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AppDelegate.h"
#import "IntertwineManager.h"

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

//TODO: Clean sign on method
- (IBAction)signOn:(id)sender {
    if ([self.signInEmailAddressField.text length]==0 || [self.signInPasswordField.text length]==0) {
        [self _signOnAlert:@"Enter an email address and password."];
    } else {
        NSString *email = self.signInEmailAddressField.text;
        NSString *password = self.signInPasswordField.text;
        
        [IntertwineManager emailSignOn:email password:password completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
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
                        NSString *serverError = [json objectForKey:@"error"];
                        if ((NSNull*)serverError != [NSNull null]) {
                            [(AppDelegate*)[[UIApplication sharedApplication] delegate] presentError:nil description:serverError];
                        } else {
                            NSString *sessionKey = [json objectForKey:@"session_key"];
                            NSString *accountID = [json objectForKey:@"account_id"];
                            [self signInWithSessionKey:sessionKey andAccountID:accountID];
                        }
                        
                    }
                }
            } else if (connectionError) {
                NSLog(@"%@", connectionError);
            }
        }];

    }
}






// This method will be called when the user information has been fetched
- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    NSString *facebookID = user.objectID;
    NSString *username = user.name;
    NSString *first = nil;
    NSString *last = nil;
    NSArray *names = [username componentsSeparatedByString:@" "];
    first = [names firstObject];
    if ([names count] > 1)
        last = [names lastObject];
    [IntertwineManager createAccountFirst:first last:last email:nil facebook:facebookID password:nil completion:nil];
    [self presentHome];
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
    self.fbLoginView.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.fbLoginView.delegate = self;
    [self _dismissEmailSignInView:NO];
    // Do any additional setup after loading the view, typically from a nib.
}


#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Setup of Navigation Controllers

- (UINavigationController*) friendsNavigationController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Friends"];
    vc.title = @"Friends";
    UINavigationController *friendsNav = [[UINavigationController alloc] initWithRootViewController:vc];
    return friendsNav;
}



#pragma mark - Sign In Delegate

- (void)presentHome {
    UINavigationController *friendsNav = [self friendsNavigationController];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = [[NSArray alloc] initWithObjects:friendsNav, nil];
    
    
    [self presentViewController:tabBarController animated:YES completion:nil];
}

- (void)signInWithSessionKey:(NSString*)sessionKey andAccountID:(NSString *)accountID{
    [IntertwineManager setHashkey:sessionKey];
    [IntertwineManager setAccountID:accountID];
    [self presentHome];
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
