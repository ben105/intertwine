//
//  NewsfeedViewController.h
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface NewsfeedViewController : UIViewController

@property (nonatomic, weak) id <FBGraphUser> user;

@property (nonatomic, weak) IBOutlet FBProfilePictureView *profilePictureView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

- (IBAction)done:(id)sender;

@end
