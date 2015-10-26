//
//  ITActivityViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 6/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ITDynamicBannerViewController.h"

@interface ITActivityViewController : ITDynamicBannerViewController

/* This array will hold EventObject instances that represent instances
 * of an event from the databse. */
@property (nonatomic, strong) NSMutableArray *events;

@end
