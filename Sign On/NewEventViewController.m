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

NSString *kCollectionIdentifier = @"cell";

@interface NewEventViewController ()

@end

@implementation NewEventViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCollectionIdentifier];
    [self.collectionView registerClass:[EventCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    
    self.uninvitedFriends = [[NSMutableArray alloc] initWithArray:self.friends];
    self.invitedFriends = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}








#pragma mark - UICollectionView Data Source

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(20, 20, 20, 20);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.invitedFriends count];
    }
    return [self.uninvitedFriends count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor blackColor];
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(0., 30.);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionHeaders = [[NSArray alloc] initWithObjects:@"Invited", @"Friends",nil];
    if (kind == UICollectionElementKindSectionHeader) {
        EventCollectionReusableView *reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                    withReuseIdentifier:@"header"
                                                                                           forIndexPath:indexPath];
        
        reusableView.textLabel.text = [sectionHeaders objectAtIndex:indexPath.section];
        return reusableView;
    }
    return nil;
}


# pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        Friend *friend = [self.invitedFriends objectAtIndex:indexPath.row];
        [self.uninvitedFriends addObject:friend];
        [self.invitedFriends removeObjectAtIndex:indexPath.row];
    } else if (indexPath.section == 1) {
        Friend *friend = [self.uninvitedFriends objectAtIndex:indexPath.row];
        [self.invitedFriends addObject:friend];
        [self.uninvitedFriends removeObjectAtIndex:indexPath.row];
    }
    [self.collectionView reloadData];
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
