//
//  ITActivityViewController.m
//  Intertwine
//
//  Created by Ben Rooke on 6/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ITActivityViewController.h"
#import "Friend.h"
#import "IntertwineManager+Activity.h"
#import "CommentViewController.h"
#import "EventObject.h"
#import "ITBannerTableView.h"

@interface ITActivityViewController ()

@end

@implementation ITActivityViewController

#pragma mark - Load Event Data

- (void) _loadEvents {
    [IntertwineManager getActivityFeedWithResponse:^(id json, NSError *error, NSURLResponse *response) {
        if(error) {
            NSLog(@"Error occured!!\n%@", error);
            return;
        }
        
        // Date formatter used in loop.
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ss"];
        
        [self.events removeAllObjects];
        for ( NSDictionary *eventDictionary in json ) {
            EventObject *event = [[EventObject alloc] init];
            event.eventID = [eventDictionary objectForKey:@"id"];
            event.eventTitle = [eventDictionary objectForKey:@"title"];
            event.eventDescription = [eventDictionary objectForKey:@"description"];
            
            // Get the updated time (for sorting later)
            NSString *timeString = [eventDictionary objectForKey:@"updated_time"];
            event.updatedTime = [format dateFromString:timeString];
            
            // Inititate the creator from the creator dictionary
            NSDictionary *creatorDictionary = [eventDictionary objectForKey:@"creator"];
            event.creator = [[Friend alloc] init];
            event.creator.first = [creatorDictionary objectForKey:@"first"];
            event.creator.last = [creatorDictionary objectForKey:@"last"];
            event.creator.accountID = [creatorDictionary objectForKey:@"id"];
            event.creator.facebookID = [creatorDictionary objectForKey:@"facebook_id"];
            event.creator.emailAddress = [creatorDictionary objectForKey:@"email"];
            
            // Assign the attendees
            NSArray *attendeeList = [eventDictionary objectForKey:@"attendees"];
            NSMutableArray *attendees = [[NSMutableArray alloc] init];
            for ( NSDictionary *attendeesDictionary in attendeeList) {
                Friend *attendee = [[Friend alloc] init];
                attendee.first = [attendeesDictionary objectForKey:@"first"];
                attendee.last = [attendeesDictionary objectForKey:@"last"];
                attendee.emailAddress = [attendeesDictionary objectForKey:@"email"];
                attendee.facebookID = [attendeesDictionary objectForKey:@"facebook_id"];
                attendee.accountID = [attendeesDictionary objectForKey:@"id"];
                [attendees addObject:attendee];
            }
            event.attendees = attendees;
            [self.events addObject:event];
        }
        //        self.eventCountLabel.text = [NSString stringWithFormat:@"%lu", [self.events count]];
        //        [self.eventsTableView reloadData];
        
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
        [self.events sortUsingDescriptors:@[sortByDate]];
        [self.contentTableView reloadData];
    }];
}

#pragma mark - Event Cell Delegate

- (void) presentCommentsWithEvent:(EventObject *)event {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CommentViewController *commentVC = [storyboard instantiateViewControllerWithIdentifier:@"Comment"];
    commentVC.event = event;
    [self presentViewController:commentVC animated:YES completion:nil];
}


#pragma mark - Initialization

- (id)init {
    return [super initWithBannerTitle:@"Activity"
                   bannerImage:[UIImage imageNamed:@"home-icon.png"]
                          data:nil];
}


#pragma mark - View Delegate Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.events = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self _loadEvents];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CommentViewController *commentVC = [storyboard instantiateViewControllerWithIdentifier:@"Comment"];
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    commentVC.event = event;
    [self presentViewController:commentVC animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return outterCellHeight;
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.events count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventTableViewCell *cell = (EventTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[EventTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell" indentLength:10.0];
    }
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    cell.event = event;
    cell.delegate = self;
    cell.eventLabel.text = event.eventTitle;
    
    NSString *facebookID = event.creator.facebookID;
    
    [cell setCreatorThumbnailWithID:facebookID facebook:YES];
    [cell setAttendees:[event attendees]];
    
    return cell;
}

@end
