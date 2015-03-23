//
//  SettingsViewController.m
//  Sign On
//
//  Created by Ben Rooke on 3/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "SettingsViewController.h"
#import "IntertwineManager.h"
#import <FacebookSDK/FacebookSDK.h>

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (IBAction)logout:(id)sender {
    AccountType accountType = [IntertwineManager accountType];
    if (accountType == kAccountTypeFacebook) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    [IntertwineManager clearCredentialCache];
    [self.delegate touchedLogout];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
