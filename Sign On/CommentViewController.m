//
//  CommentViewController.m
//  Intertwine
//
//  Created by Ben Rooke on 4/11/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "CommentViewController.h"
#import "EventCollectionViewCell.h"
#import "EventObject.h"
#import <FacebookSDK/FacebookSDK.h>


const NSString *kCommentCollectionIdentifier = @"commentvc_attendee";

@interface CommentViewController ()
- (void)_registerForKeyboardNotifications;
- (void)_keyboardWasShown:(NSNotification*)aNotification;
- (void)_keyboardWillBeHidden:(NSNotification*)aNotification;
@end

@implementation CommentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.titleLabel.text = self.event.eventTitle;
    [self.attendeesCollectionView registerClass:[EventCollectionViewCell class] forCellWithReuseIdentifier:(NSString*)kCommentCollectionIdentifier];
    [self _registerForKeyboardNotifications];
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


- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)_registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}



#pragma mark - Keyboard Notifications

- (void)_keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    NSNumber *animationDurationNumber = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    double animationDuration = [animationDurationNumber doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGFloat width = CGRectGetWidth(self.view.frame);
        CGFloat height = CGRectGetHeight(self.view.frame);
        self.view.frame = CGRectMake(0, 0 - kbSize.height, width, height);
    }];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)_keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSNumber *animationDurationNumber = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    double animationDuration = [animationDurationNumber doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGFloat width = CGRectGetWidth(self.view.frame);
        CGFloat height = CGRectGetHeight(self.view.frame);
        self.view.frame = CGRectMake(0, 0, width, height);
    }];
}



#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.events count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    [cell setCreatorThumbnailWithID:facebookID facebook:YES];
    [cell setAttendeeCount:[event.attendees count]];
    
    return cell;
}





#pragma mark - UICollectionView Data Source

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //You may want to create a divider to scale the size by the way..
    return CGSizeMake(60.0, 70.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 20, 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.event.attendees count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // Attempt to get the event collection cell.
    EventCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(NSString*)kCommentCollectionIdentifier forIndexPath:indexPath];
    
    // Pick the section type.
    // Get the account's Facebook ID.
    NSString *profileID = [[self.event.attendees objectAtIndex:indexPath.row] facebookID];
    
    if ((NSNull*)profileID == [NSNull null]) {
        profileID = @"0";
    }
    
    // Set the picture and name.
    cell.profilePicture.profileID = profileID;
    cell.nameLabel.text = [[self.event.attendees objectAtIndex:indexPath.row] first];
    cell.nameLabel.textColor = [UIColor blackColor];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


# pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}





@end
