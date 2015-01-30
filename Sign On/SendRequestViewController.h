//
//  SendRequestViewController.h
//  Sign On
//
//  Created by Ben Rooke on 1/27/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SendRequestViewController : UIViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *friendsTableView;
@property (nonatomic, strong) NSArray *friendSuggestions;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSMutableArray *tableData;

@property (nonatomic, strong) NSArray *sectionTitles;

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@end
