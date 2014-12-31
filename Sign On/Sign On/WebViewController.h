//
//  WebViewController.h
//  Sign On
//
//  Created by Ben Rooke on 11/29/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, weak) IBOutlet UILabel *navTitle;
@property (nonatomic, copy) NSURL *url;

- (IBAction)done:(id)sender;

@end
