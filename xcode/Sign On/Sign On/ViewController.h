//
//  ViewController.h
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class ActivityViewController;


@protocol SignInDelegate <NSObject>
@required
- (void)signInWithSessionKey:(NSString*)sessionKey andAccountID:(NSString*)accountID;
@end

@interface ViewController : UIViewController <SignInDelegate, FBLoginViewDelegate>

@property (nonatomic, strong) ActivityViewController *activityViewController;

/*
 * Logging into Facebook
 */
@property (nonatomic, weak) IBOutlet FBLoginView *fbLoginView;
- (IBAction)faceookLogin:(id)sender;

/*
 * Signing into email
 */
@property (nonatomic, weak) IBOutlet UIView *emailSignInView;
@property (nonatomic, weak) IBOutlet UITextField *signInEmailAddressField;
@property (nonatomic, weak) IBOutlet UITextField *signInPasswordField;


/* Sign Up process */
- (IBAction)dismissEmailSignIn:(id)sender;
- (IBAction)presentEmailSignIn:(id)sender;

- (IBAction)signUp:(id)sender;
- (IBAction)signOn:(id)sender;


@property (nonatomic, strong) UIView *shieldView;




@end

