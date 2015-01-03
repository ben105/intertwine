//
//  ViewController.h
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>


@protocol SignInDelegate <NSObject>
@required
- (void)signInWithEmail:(NSString*)email;
@end

@interface ViewController : UIViewController <SignInDelegate, FBLoginViewDelegate>

@property (nonatomic, weak) IBOutlet FBLoginView *fbLoginView;

@property (nonatomic, weak) IBOutlet UIView *emailSignInView;

@property (nonatomic, weak) IBOutlet UITextField *signInEmailAddressField;
@property (nonatomic, weak) IBOutlet UITextField *signInPasswordField;

- (IBAction)faceookLogin:(id)sender;

- (IBAction)dismissEmailSignIn:(id)sender;
- (IBAction)presentEmailSignIn:(id)sender;

- (IBAction)signUp:(id)sender;
- (IBAction)signOn:(id)sender;

@end

