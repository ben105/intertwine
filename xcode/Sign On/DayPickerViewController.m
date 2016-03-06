//
//  DayPickerViewController.m
//  DatePicker
//
//  Created by Ben Rooke on 1/18/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "DayPickerViewController.h"
#import "NSDate+DaysOfYear.h"
#import "IntertwineCalendarDayCell.h"
#import "SemesterPage.h"


const CGFloat DayPickerSectionHeaderHeight = 100.0;

const CGFloat SlidePercentageSignifigance = 0.09;

/*                      J   F   M   A    M   J   J  A   S    O   N   D   */
int daysInMonth[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

char monthNames[12][12] = { "January", "Febuary", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};

@interface DayPickerViewController ()
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIScrollView *pickerScrollView;
/* For optimization purposes, we store all the today values from the date component class. */
@property (nonatomic, strong) NSDate *today;
@property (nonatomic) NSInteger todayDay;
@property (nonatomic) NSInteger todayMonth;
@property (nonatomic) NSInteger todayYear;
- (NSDateComponents*)_dateComponentsForSection:(NSInteger)section;
- (void)_setSemesterTitleForCell:(IntertwineCalendarDayCell*)cell;
- (void)_tellDelegateGoBack;
- (void)_resetScrollableCells;
@end

@implementation DayPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.today = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.today];
    self.todayDay = components.day;
    self.todayMonth = components.month - 1; // We need this to be zero indexed.
    self.todayYear = components.year;

    [self.view addSubview:self.pickerScrollView];
    [self.view addSubview:self.backButton];
    [self.pickerScrollView addSubview:self.dayPickerTableView];
    
    CGPoint center = self.semesterPickerView.center;
    center.x = center.x * 3.0;
    self.semesterPickerView.center = center;
    [self.pickerScrollView addSubview:self.semesterPickerView];
    
    [self.pickerScrollView addSubview:self.timePickerView];
    
    self.view.backgroundColor = [UIColor colorWithRed:18.0/255.0 green:48.0/255.0 blue:78.0/255.0 alpha:1.0];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Prep For Semester View

- (void)_setSemesterTitleForCell:(IntertwineCalendarDayCell*)cell {
    NSString *dayString = [NSString stringWithFormat:@"%@ %@", [cell getDayOfWeek], [cell getDay]];
    self.semesterPickerView.dayHeaderLabel.text = dayString;
    /* Figure out which month we're in. */
    NSIndexPath *indexPath = [self.dayPickerTableView indexPathForCell:cell];
    NSDateComponents *components = [self _dateComponentsForSection:indexPath.section];
    self.semesterPickerView.monthHeaderLabel.text = [NSString stringWithCString:monthNames[components.month - 1]
                                                                       encoding:NSUTF8StringEncoding];
}


#pragma mark - UITableView Data Source and Delegate

/* We want to show the month in the header. */

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return DayPickerSectionHeaderHeight;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSDateComponents *components = [self _dateComponentsForSection:section];
    NSString *month = [NSString stringWithCString:monthNames[components.month - 1] encoding:NSUTF8StringEncoding];
    CGFloat width = CGRectGetWidth(self.dayPickerTableView.frame);
    UILabel *monthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, DayPickerSectionHeaderHeight)];
    monthLabel.text = month;
    monthLabel.textColor = [UIColor whiteColor];
    monthLabel.backgroundColor = [UIColor colorWithRed:18.0/255.0 green:48.0/255.0 blue:78.0/255.0 alpha:1.0];
    monthLabel.textAlignment = NSTextAlignmentCenter;
    monthLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    return monthLabel;
}


//- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    NSDateComponents *components = [self _dateComponentsForSection:section];
//    return [NSString stringWithCString:monthNames[components.month - 1] encoding:NSUTF8StringEncoding];
//}

- (NSDateComponents*)_dateComponentsForSection:(NSInteger)section {
    /* The section is a 0-index offset of today's month. */
    NSInteger badMonthNumber = self.todayMonth + section;
    /* It's possible that this number has overflowed the max 11 value, and needs to rollover.
     * If we mod the number by 12, and we are expecting dates 0-11, then we will be able to
     * successfully roll it over. (i.e. 11 = december    you add 1 and mod 12 you get 0. 0 = January) */
    NSInteger monthNumber = badMonthNumber % 12;
//    NSLog(@"Section: %ld\nMonth: %ld\n\n", section, monthNumber);
    /* But if we overflowed, that means we've progressed a year. We can calculate how many years
     * we've progressed by doing the division. */
    NSInteger yearsProgressed = badMonthNumber / 12;    // We want to keep this an integer division.
    NSInteger yearNumber = self.todayYear + yearsProgressed;
    
    NSDateComponents *components = [NSDateComponents new];
    components.month = monthNumber + 1;
    components.year = yearNumber;
    
    return components;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 12;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDateComponents *components = [self _dateComponentsForSection:section];
    NSInteger monthIndex = components.month - 1;

    NSInteger numberOfDays = daysInMonth[monthIndex];
    
    /* We need to check if it's a leap year! */
    if (monthIndex == 1 && [NSDate isLeapYear:components.year]) {
        numberOfDays ++;
    }
    
    /* One last exception we should check. If we are on the current month, we don't want
     * to display all the days. Only the days that are left. */
    if (monthIndex == self.todayMonth && components.year == self.todayYear) {
        numberOfDays -= self.todayDay;
    }
    
    return numberOfDays;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"intertwine_calendar_cell";
    IntertwineCalendarDayCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[IntertwineCalendarDayCell alloc] initWithWidth:CGRectGetWidth([[UIScreen mainScreen] bounds]) reuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    NSDateComponents *components = [self _dateComponentsForSection:indexPath.section];
    NSInteger monthIndex = components.month - 1;
    components.day = indexPath.row + 1;
    if (monthIndex == self.todayMonth && components.year == self.todayYear) {
        components.day += self.todayDay - 1;
    }
    cell.date = [NSDate dateFromComponents:components];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [IntertwineCalendarDayCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self.delegate respondsToSelector:@selector(didSelectStartDate:semesterIndex:)]) {
        IntertwineCalendarDayCell *cell = [self.dayPickerTableView cellForRowAtIndexPath:indexPath];
        [self.delegate didSelectStartDate:[cell stringFromDate] semesterIndex:0];
    }
}

#pragma mark - Convenience Methods

- (void)_resetScrollableCells {
    NSArray<__kindof SlideToChooseTableViewCell*> *cells = [self.dayPickerTableView visibleCells];
    [cells makeObjectsPerformSelector:@selector(resetScrollableCell)];
}

#pragma mark - Cell Scrolling Delegate

- (void)tableViewCell:(SlideToChooseTableViewCell*)cell  scrollProgress:(CGFloat)percentage {
//    NSIndexPath *indexPath = [self.dayPickerTableView indexPathForCell:cell];
    if (percentage > 0) {
        if (percentage < SlidePercentageSignifigance) {
            percentage = 0;
        } else {
            [self _setSemesterTitleForCell:(IntertwineCalendarDayCell *)cell];
        }
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        CGFloat moveTo = screenWidth * percentage;
        [self.pickerScrollView setContentOffset:CGPointMake(moveTo, 0)];
    }
    
    self.pickerScrollView.scrollEnabled = percentage >= 1;
    if (percentage >= 1) {
        [self _resetScrollableCells];
    }
}

//- (void)tableViewCellDidEndDragging:(SlideToChooseTableViewCell *)cell {
//    
//}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.pickerScrollView) {
        CGFloat viewWidth = CGRectGetWidth(self.view.frame);
        NSUInteger pageNumber = scrollView.contentOffset.x / viewWidth;
        self.pickerScrollView.scrollEnabled = pageNumber <= 1;
        if (pageNumber > 1) {
            [self _resetScrollableCells];
        }
    }
}

#pragma mark - Semester View Delegate

- (void)semesterName:(NSString *)semesterName scrollProgress:(CGFloat)percentage {
    if (percentage > 0) {
        if (percentage < SlidePercentageSignifigance) {
            percentage = 0;
        }
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        CGFloat moveTo = screenWidth * percentage;
        [self.pickerScrollView setContentOffset:CGPointMake(screenWidth + moveTo, 0)];
    }
}

#pragma mark - Protocol Definitions

- (void)_tellDelegateGoBack {
    CGFloat viewWidth = CGRectGetWidth(self.view.frame);
    NSUInteger pageNumber = self.pickerScrollView.contentOffset.x / viewWidth;
    if (pageNumber >= 1) {
        NSUInteger scrollToPage = pageNumber - 1;
        [self.pickerScrollView setContentOffset:CGPointMake(scrollToPage * viewWidth, 0) animated:YES];
    } else if ([self.delegate respondsToSelector:@selector(shouldDismissDayPickerViewController)]) {
        [self.delegate shouldDismissDayPickerViewController];
    }
}


#pragma mark - Lazy Loading

- (UIButton*)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backButton.frame = CGRectMake(0, 0, 60.0, DayPickerSectionHeaderHeight);
        [_backButton setImage:[UIImage imageNamed:@"SlideLeft.png"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(_tellDelegateGoBack) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UITableView*)dayPickerTableView {
    if (!_dayPickerTableView) {
        _dayPickerTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] bounds] style:UITableViewStylePlain];
        _dayPickerTableView.backgroundColor = [UIColor clearColor];
        _dayPickerTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _dayPickerTableView.delegate = self;
        _dayPickerTableView.dataSource = self;
    }
    return _dayPickerTableView;
}

- (SemesterPage*)semesterPickerView {
    if (!_semesterPickerView) {
        CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        CGFloat height = CGRectGetHeight([[UIScreen mainScreen] bounds]);
        _semesterPickerView = [[SemesterPage alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _semesterPickerView.semesterView.delegate = self;
    }
    return _semesterPickerView;
}

- (UIView*)timePickerView {
    if (!_timePickerView) {
        CGFloat centerX = CGRectGetMidX([[UIScreen mainScreen] bounds]);
        CGFloat centerY = CGRectGetMidY([[UIScreen mainScreen] bounds]);
        CGFloat width = 200.0;
        CGFloat height = 400.0;
        _timePickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _timePickerView.center = CGPointMake(centerX * 5, centerY);
    }
    return _timePickerView;
}

- (UIScrollView*)pickerScrollView {
    if (!_pickerScrollView) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat contentWidth = CGRectGetWidth(screenRect);
        CGFloat contentHeight = CGRectGetHeight(screenRect);
        _pickerScrollView = [[UIScrollView alloc] initWithFrame:screenRect];
        _pickerScrollView.contentSize = CGSizeMake(contentWidth * 2.0, contentHeight);
        _pickerScrollView.scrollEnabled = NO;
        _pickerScrollView.delegate = self;
        _pickerScrollView.pagingEnabled = YES;
    }
    return _pickerScrollView;
}

@end
