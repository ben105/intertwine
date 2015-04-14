//
//  NewEventViewController.m
//  Sign On
//
//  Created by Ben Rooke on 3/21/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "NewEventViewController.h"
#import "Friend.h"
#import "EventCollectionReusableView.h"
#import "EventCollectionViewCell.h"
#import "IntertwineManager+Events.h"
#import <FacebookSDK/FacebookSDK.h>

NSString *kCollectionIdentifier = @"cell";

@interface NewEventViewController ()

@end

@implementation NewEventViewController

- (IBAction)dismissKeyboard:(id)sender {
    [sender resignFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.invitedCollectionView registerClass:[EventCollectionViewCell class] forCellWithReuseIdentifier:kCollectionIdentifier];
    [self.invitedCollectionView registerClass:[EventCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    [self.uninvitedCollectionView registerClass:[EventCollectionViewCell class] forCellWithReuseIdentifier:kCollectionIdentifier];
    [self.uninvitedCollectionView registerClass:[EventCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    
    self.uninvitedFriends = [[NSMutableArray alloc] initWithArray:self.friends];
    self.invitedFriends = [[NSMutableArray alloc] init];
    
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(cancel:)];
    gesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:gesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Navigational Buttons

- (IBAction)cancel:(id)sender {
    [self.delegate closeEventCreation];
}

- (IBAction)create:(id)sender {
    NSString *title = self.titleField.text;
    if ([title isEqualToString:@""] || !title) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Enter a title for the event."
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    if ([self.invitedFriends count] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Invite at least one friend, first."
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    [IntertwineManager createEvent:title withFriends:self.invitedFriends withResponse:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"An error has occurred trying to create an event!\n%@", error);
            return;
        }
        [self.delegate closeEventCreation];
    }];
}





#pragma mark - UICollectionView Data Source

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //You may want to create a divider to scale the size by the way..
    return CGSizeMake(60.0, 90.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 20, 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.invitedCollectionView) {
          return [self.invitedFriends count];
    }
    return [self.uninvitedFriends count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // Attempt to get the event collection cell.
    EventCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionIdentifier forIndexPath:indexPath];
    
    // Start with an empty section.
    NSMutableArray *sectionArray = nil;

    // Pick the section type.
    if (collectionView == self.invitedCollectionView) {
        sectionArray = self.invitedFriends;
    } else {
        sectionArray = self.uninvitedFriends;
    }
    
    // Get the account's Facebook ID.
    NSString *profileID = [[sectionArray objectAtIndex:indexPath.row] facebookID];
    
    if ((NSNull*)profileID == [NSNull null]) {
        profileID = @"0";
    }
    
    // Set the picture and name.
    cell.profilePicture.profileID = profileID;
    cell.nameLabel.text = [[sectionArray objectAtIndex:indexPath.row] first];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(0., 40.);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    NSString *header = @"";
    if (kind == UICollectionElementKindSectionHeader) {
        if (collectionView == self.invitedCollectionView) {
            header = @"Invited";
        } else {
            header = @"Uninvited";
        }
        
        EventCollectionReusableView *reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                    withReuseIdentifier:@"header"
                                                                                           forIndexPath:indexPath];
        reusableView.textLabel.text = header;
        return reusableView;
    }
    return nil;
}


# pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.invitedCollectionView) {
        Friend *friend = [self.invitedFriends objectAtIndex:indexPath.row];
        [self.uninvitedFriends addObject:friend];
        [self.invitedFriends removeObjectAtIndex:indexPath.row];
    } else if (collectionView == self.uninvitedCollectionView) {
        Friend *friend = [self.uninvitedFriends objectAtIndex:indexPath.row];
        [self.invitedFriends addObject:friend];
        [self.uninvitedFriends removeObjectAtIndex:indexPath.row];
    }
    
    /*
     * No matter which collection view cell item was selected,
     * both collection views need to refresh.
     */
    [self.invitedCollectionView reloadData];
    [self.uninvitedCollectionView reloadData];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
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
