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
#import "ActivityViewController.h"
#import "FriendsViewController.h"
#import "ITMultipleBannersViewController.h"
#import "ITDynamicBannerViewController.h"
#import "ITActivityViewController.h"
#import "NavigationViewController.h"

const float emailSignInAnimationDuration = 0.5;

NSString *newsfeedStoryboardID = @"Newsfeed";

@interface ViewController ()


@property (nonatomic, strong) id<FBGraphUser> handledUser;

/* Present Home:
 * Called after the user has logged in, either via email
 * or Facebook.                                                 */
- (void)_presentHome;

/* Present Email Sign In View:
 * --------------------------------
 * TODO: Create Email Account View
 * --------------------------------
 * Presents the view from which a user can enter the information
 * needed to create a new account (email account).              */
- (void)_presentEmailSignInView:(BOOL)animated;

/* Resetting Email Fields:
 * Simple purpose, to reset the text fields where the user has
 * possibly entered their credentials.                          */
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
    
    if (self.handledUser == nil) {
        self.handledUser = user;
    } else if (self.handledUser == user) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_animateShieldViewDown) object:nil];
    NSString *facebookID = user.objectID;
    NSString *username = user.name;
    NSString *first = nil;
    NSString *last = nil;
    [IntertwineManager registeredFacebookID:facebookID username:username];
    NSArray *names = [username componentsSeparatedByString:@" "];
    first = [names firstObject];
    if ([names count] > 1)
        last = [names lastObject];
    [IntertwineManager createAccountFirst:first last:last email:nil facebook:facebookID password:nil completion:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        [self performSelector:@selector(_presentHome) withObject:nil afterDelay:1.0];
        
    }];

}











#pragma mark - Sign Up

- (IBAction)signUp:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EmailRegistrationViewController *registrationVC = [storyboard instantiateViewControllerWithIdentifier:@"EmailRegistration"];
    registrationVC.delegate = self;
    [self presentViewController:registrationVC animated:YES completion:nil];
}


#pragma mark - Shield View

- (void) _shieldViewUpAnimated:(BOOL)animated {
    CGRect upFrame = [[UIScreen mainScreen] bounds];
    self.shieldView.frame = upFrame;
}

- (void) _shieldViewDownAnimated:(BOOL)animated {
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    screenFrame.origin.y += screenFrame.size.height;
    self.shieldView.frame = screenFrame;
}

- (void) _animateShieldViewDown {
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    screenFrame.origin.y += screenFrame.size.height;
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.shieldView.frame = screenFrame;
                     }];
}


#pragma mark - View Load

- (void)viewDidLoad {
    [super viewDidLoad];

    self.handledUser = nil;
    
    [self.view addSubview:self.shieldView];
    
    self.fbLoginView.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.fbLoginView.delegate = self;
    [self _dismissEmailSignInView:NO];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void) viewDidAppear:(BOOL)animated {
    [self _shieldViewUpAnimated:NO];
    [self performSelector:@selector(_animateShieldViewDown) withObject:nil afterDelay:1.0];
    
    self.signInEmailAddressField.text = @"";
    self.signInPasswordField.text = @"";
    [super viewDidAppear:animated];
//    [self _presentHome];
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Sign In Delegate

- (void)_presentHome {
    
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *FBuser, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
        else {
            /* Create two dynamic banner view controllers. */
//            ITActivityViewController *activityViewController = [[ITActivityViewController alloc] init];
//            ITDynamicBannerViewController *yourViewController =
//                [[ITDynamicBannerViewController alloc] initWithBannerTitle:[IntertwineManager facebookName]
//                                                               bannerImage:facebookImage
//                                                                      data:nil];
//            ITMultipleBannersViewController *vc = [[ITMultipleBannersViewController alloc]
//                                                   initWithBannerViewControllers:@[activityViewController, yourViewController]];
//            [self presentViewController:vc animated:YES completion:nil];
            
//            _activityViewController = [ActivityViewController new];
            [self presentViewController:self.activityViewController animated:NO completion:nil];

            
//            /* Present the views. */
//            NavigationViewController *navigationVC = [NavigationViewController new];
//            [self presentViewController:navigationVC animated:YES completion:^{
//                NSLog(@"Supposedly, completed presenting view controller.");
//            }];
            
        }
    }];
    
    
    /* Instantiate all the view controller instances. */
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    ActivityViewController *activityVC = [storyboard instantiateViewControllerWithIdentifier:@"Events"];
////    activityVC.title = @"Activity";
//    
//    /* Present the views. */
//    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)signInWithSessionKey:(NSString*)sessionKey andAccountID:(NSString *)accountID{
    [IntertwineManager setTokenKey:sessionKey];
    [IntertwineManager setAccountID:accountID];
    [self _presentHome];
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


#pragma mark - UI Elements

-(ActivityViewController*)activityViewController {
    if (!_activityViewController) {
        _activityViewController = [ActivityViewController new];
    }
    return _activityViewController;
}

- (UIView*) shieldView {
    if (!_shieldView) {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        
        _shieldView = [[UIView alloc] initWithFrame:screenBounds];
        _shieldView.backgroundColor = [UIColor whiteColor];
    
        
        NSString *fontName = @"HelveticaNeue-Light";
        CGFloat titleFontSize = 30.0;
        
        CGFloat subtitleFontSize = 18.0;
        CGFloat textHeight = 36.0;
        
        CGFloat inset = 10.0;
        CGFloat middleOfScreen = CGRectGetMidY(screenBounds);
        CGFloat screenWidth = CGRectGetWidth(screenBounds);
        CGFloat textWidth = screenWidth - (inset * 2.0);
        
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, middleOfScreen - textHeight, textWidth, textHeight)];
        titleLabel.font = [UIFont fontWithName:fontName size:titleFontSize];
        titleLabel.text = @"Intertwine";
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(titleLabel.frame), textWidth, textHeight)];
        subtitleLabel.font = [UIFont fontWithName:fontName size:subtitleFontSize];
        subtitleLabel.text = @"Ben Rooke";
        subtitleLabel.textColor = [UIColor blackColor];
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        
        UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, CGRectGetMaxY(subtitleLabel.frame) + textHeight, textWidth, textHeight)];
        versionLabel.font = [UIFont fontWithName:fontName size:subtitleFontSize];
        versionLabel.text = @"Intertwine v0.2 (Alpha)";
        versionLabel.textColor = [UIColor blackColor];
        versionLabel.backgroundColor = [UIColor clearColor];
        versionLabel.textAlignment = NSTextAlignmentCenter;
        
        [_shieldView addSubview:titleLabel];
        [_shieldView addSubview:subtitleLabel];
        [_shieldView addSubview:versionLabel];
    }
    return _shieldView;
}


@end
