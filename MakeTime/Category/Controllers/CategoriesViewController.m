//
//  CategoriesViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/15/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "CategoriesViewController.h"
#import "CategoriesTableViewCell.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "AppDelegate.h"
#import "EditCategoriesViewController.h"
#import "AddCalendarViewController.h"
#import "EventsViewController.h"
#import "UIColor+Converter.h"

@interface CategoriesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *categoriesTableView;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;

@property (strong, nonatomic) NSIndexPath *checkedIndexPath;
@property (assign, nonatomic) NSInteger checkedRow;

@end


@implementation CategoriesViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customizeLabel];
    [self configureButtonsForTabBar];
    [self configureViewAndTableView];
}

- (void)loadCalendarData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self assignCalendarColors];
        __weak CategoriesViewController *weakSelf = self;
        [[EventManager sharedManager] loadCustomCalendarsWithCompletion:^(NSArray *calendars) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.customCalendars = calendars;
                [weakSelf.categoriesTableView reloadData];
            });
        }];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reload table view and the custom calendars when navigating back from AddCalendarVC
    [self loadCalendarData];
}


#pragma mark - Selectors


- (void)pushAddCategoryVC {
    [self.navigationController pushViewController:[AddCalendarViewController new] animated:YES];
}


#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.customCalendars count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoriesTableViewCell *cell = (CategoriesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"CategoriesTableViewCell"];
    cell.backgroundColor = [UIColor clearColor];
    
    EKCalendar *cal = self.customCalendars[indexPath.row];
    cell.categoriesLabel.text = cal.title;
    cell.categoriesLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:15.0f];
    
    UIColor *calendarColor = [UIColor colorWithCGColor:cal.CGColor];
    CALayer *layer = [CALayer layer];
    layer.cornerRadius = cell.categoriesColorView.bounds.size.width / 2;
    layer.frame = cell.categoriesColorView.bounds;
    layer.backgroundColor = calendarColor.CGColor;
    [cell.categoriesColorView.layer addSublayer:layer];
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    EventManager *eventManager = [EventManager sharedManager];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSError *error;
        EKCalendar *cal = self.customCalendars[indexPath.row];
        [eventManager removeCustomCalendarIdentifier:cal.calendarIdentifier];
        if (![eventManager.eventStore removeCalendar:cal commit:YES error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            NSLog(@"Successfully deleted calendar titled %@", cal.title);
        }
    }
    
    // Re-load all calendars, delete the row with an animation (which also refreshes the table view)
    __weak CategoriesViewController *weakSelf = self;
    [eventManager loadCustomCalendarsWithCompletion:^(NSArray *calendars) {
        weakSelf.customCalendars = calendars;
        [weakSelf.categoriesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
}


#pragma mark - UITableViewDelegate


//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    EKCalendar *cal = self.customCalendars[indexPath.row];
//
//    EditCategoriesViewController *editCategoriesVC = [[EditCategoriesViewController alloc] initWithCalendar:cal];
//    editCategoriesVC.indexOfCategory = indexPath.row;
//
//    // Assign the checked row value to the index of the calendar's color
//    UIColor *colorOfCal = [UIColor colorWithCGColor:cal.CGColor];
//    for (NSInteger i = 0; i < [self.calendarUIColors count]; i++) {
//        if ([colorOfCal isEqualToColor:self.calendarUIColors[i]]) {
//            editCategoriesVC.checkedRow = i;
//        }
//    }
//
//    [self.navigationController pushViewController:editCategoriesVC animated:YES];
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EventsViewController *eventsViewController = [[EventsViewController alloc] initWithCalendar:self.customCalendars[indexPath.row]];
    [self.navigationController pushViewController:eventsViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoriesTableViewCell *cell = (CategoriesTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    // Revert background color of cell to clear color.
    [UIView animateWithDuration:0.36
                          delay:0.0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [cell setBackgroundColor:[UIColor clearColor]];
                     }
                     completion:nil];
}

#pragma mark - Private Methods



- (void)customizeLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.text = @"Categories";
    [label sizeToFit];
    self.navigationItem.titleView = label;
}

- (void)configureButtonsForTabBar {
    NSDictionary *textAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:14.0], NSForegroundColorAttributeName : [UIColor blackColor] };
    //    UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
    //                                                                       style:UIBarButtonItemStylePlain
    //                                                                      target:self
    //                                                                      action:@selector(pushEditEventVC)];
    //    leftButtonItem.tintColor = [UIColor blackColor];
    //    [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    //    [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    //    self.navigationItem.leftBarButtonItem = leftButtonItem;
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(pushAddCategoryVC)];
    rightButtonItem.tintColor = [UIColor blackColor];
    [rightButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    [rightButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
}

- (void)configureViewAndTableView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.categoriesTableView.backgroundColor = [UIColor clearColor];
    
    self.navigationController.navigationBar.clipsToBounds = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Load the NIB file, and register the NIB (which contains the cell)
    UINib *nib = [UINib nibWithNibName:@"CategoriesTableViewCell" bundle:nil];
    [self.categoriesTableView registerNib:nib forCellReuseIdentifier:@"CategoriesTableViewCell"];
    
    // Eliminate line separators for the UITableView
    //  self.categoriesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Insert a dummy footer view which will only show amount of cells you returned in tableView:numberOfRowsInSection:
    self.categoriesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Do NOT modify the content area of the scroll view using the safe area insets
    if (@available(iOS 11.0, *)) {
        self.categoriesTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    // Dont let scroll view bounce past the end of the bounds
//    self.categoriesTableView.alwaysBounceVertical = NO;
}

- (void)giveGradientBackgroundColor {
    // Create an overlay view to give a gradient background color
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 3000);
    UIView *overlayView = [[UIView alloc] initWithFrame:frame];
    UIColor *skyBlueLight = [UIColor colorWithHue:0.57 saturation:0.90 brightness:0.98 alpha:1.0];
    overlayView.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom
                                                        withFrame:frame
                                                        andColors:@[[UIColor whiteColor], skyBlueLight]];
    [self.view insertSubview:overlayView atIndex:0];
}

- (void)assignCalendarColors {
    UIColor *hotPink = [UIColor colorWithRed:(238/255.0) green:(106/255.0) blue:(167/255.0) alpha:1.0];
    UIColor *turquoise = [UIColor colorWithRed:(64/255.0) green:(224/255.0) blue:(208/255.0) alpha:1.0];
    UIColor *darkOrchid = [UIColor colorWithRed:(154/255.0) green:(50/255.0) blue:(205/255.0) alpha:1.0];
    UIColor *darkOrange = [UIColor colorWithRed:(255/255.0) green:(140/255.0) blue:(0/255.0) alpha:1.0];
    UIColor *chartreuse = [UIColor colorWithRed:(118/255.0) green:(238/255.0) blue:(0/255.0) alpha:1.0];
    UIColor *yellow = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(0/255.0) alpha:1.0];
    
    self.calendarUIColors = @[hotPink, turquoise, darkOrchid, darkOrange, chartreuse, yellow];
    self.calendarStringColors = @[@"Pink", @"Turquoise", @"Orchid", @"Orange", @"Chartreuse", @"Yellow"];
}


#pragma mark - Custom Getters


- (AppDelegate *)appDelegate {
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}


@end
