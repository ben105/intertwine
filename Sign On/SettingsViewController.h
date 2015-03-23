//
//  SettingsViewController.h
//  Sign On
//
//  Created by Ben Rooke on 3/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SettingsDelegate <NSObject>
@required
- (void) touchedLogout;
@end


@interface SettingsViewController : UIViewController

@property (nonatomic, assign) id<SettingsDelegate> delegate;

- (IBAction)logout:(id)sender;

@end
