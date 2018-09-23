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

@property (strong, nonatomic) NSDictionary<UIColor *, NSArray<EKCalendar *> *> *sections;
@property (strong, nonatomic) NSArray<UIColor *> *colors;

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
        __weak CategoriesViewController *weakSelf = self;
        [[EventManager sharedManager] loadCustomCalendarsWithCompletion:^(NSArray *calendars) {
            weakSelf.customCalendars = calendars;
            [weakSelf createSectionsForCalendars:calendars completion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.categoriesTableView reloadData];
                });
            }];
        }];
    });
}

- (void)createSectionsForCalendars:(NSArray *)calendars completion:(void (^)(void))completion {
    NSMutableDictionary<UIColor *, NSMutableArray<EKCalendar *> *> *sections = [NSMutableDictionary dictionary];
    
    for (EKCalendar *calendar in self.customCalendars) {
        UIColor *color = [UIColor colorWithCGColor:calendar.CGColor];
        
        NSMutableArray *calendars = [sections objectForKey:color];
        if (calendars == nil) {
            calendars = [NSMutableArray array];
            
            [sections setObject:calendars forKey:color];
        }
        
        [calendars addObject:calendar];
    }
    
    self.sections = (NSDictionary<UIColor *, NSArray<EKCalendar *> *> *)sections;
    self.colors = [self.sections allKeys];
    
    completion();
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reload table view and the custom calendars when navigating back from AddCalendarVC
    [self loadCalendarData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    [self.categoriesTableView setEditing:NO animated:NO];
//    self.navigationItem.leftBarButtonItem.title = @"Edit";
}


#pragma mark - Selectors


- (void)pushAddCategoryVC {
    [self.navigationController pushViewController:[AddCalendarViewController new] animated:YES];
}


#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    UIColor *color = [self.colors objectAtIndex:section];
    NSArray *calendars = [self.sections objectForKey:color];
    return [calendars count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    UIColor *color = [self.colors objectAtIndex:section];
    EventManager *eventManager = [EventManager sharedManager];
    for (UIColor *colorKey in eventManager.colorStrings) {
        if ([colorKey isEqualToColor:color]) {
            return [eventManager.colorStrings objectForKey:colorKey];
        }
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoriesTableViewCell *cell = (CategoriesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"CategoriesTableViewCell"];
    cell.backgroundColor = [UIColor whiteColor];
    
    UIColor *color = [self.colors objectAtIndex:indexPath.section];
    NSArray *calendarsForColor = [self.sections objectForKey:color];
    EKCalendar *calendar = [calendarsForColor objectAtIndex:indexPath.row];
    
    cell.categoriesLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0f];
    cell.categoriesLabel.text = calendar.title;
    
    UIColor *calendarColor = [UIColor colorWithCGColor:calendar.CGColor];
    CALayer *layer = [CALayer layer];
    layer.cornerRadius = cell.categoriesColorView.bounds.size.width / 2;
    layer.frame = cell.categoriesColorView.bounds;
    layer.backgroundColor = calendarColor.CGColor;
    [cell.categoriesColorView.layer addSublayer:layer];
    
    return cell;
}

//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (self.categoriesTableView.isEditing) {
//        return UITableViewCellEditingStyleDelete;
//    } else {
//        return UITableViewCellEditingStyleNone;
//    }
//}

// //  Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    __weak CategoriesViewController *weakSelf = self;
//    [self shouldProceedWithDeletingCalendar:^(BOOL shouldProceed) {
//        if (shouldProceed) {
//             EventManager *eventManager = [EventManager sharedManager];
//            if (editingStyle == UITableViewCellEditingStyleDelete) {
//                [weakSelf deleteCategoryAtIndexPath:indexPath];
//            } else {
//                [weakSelf presentEditCategoriesVC:indexPath];
//            }
//            [eventManager loadCustomCalendarsWithCompletion:^(NSArray *calendars) {
//                weakSelf.customCalendars = calendars;
//            }];
//        } else {
//            [weakSelf.categoriesTableView setEditing:NO animated:YES];
//            weakSelf.navigationItem.leftBarButtonItem.title = @"Edit";
//        }
//    }];
//}

- (void)deleteCategoryAtIndexPath:(NSIndexPath *)indexPath {
    EventManager *eventManager = [EventManager sharedManager];
    
    UIColor *color = [self.colors objectAtIndex:indexPath.section];
    NSArray *calendarsForColor = [self.sections objectForKey:color];
    EKCalendar *cal = [calendarsForColor objectAtIndex:indexPath.row];
    
    NSMutableDictionary<UIColor *, NSMutableArray<EKCalendar *> *> *mutableSections = [self.sections mutableCopy];
    NSMutableArray *mutableColors = [self.colors mutableCopy];
    
    [self.categoriesTableView beginUpdates];
    if ([calendarsForColor count] <= 1) {
        [mutableSections removeObjectForKey:color];
        [mutableColors removeObject:color];
        self.sections = mutableSections;
        self.colors = mutableColors;
        [self.categoriesTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                                withRowAnimation:UITableViewRowAnimationFade];
    } else {
        NSMutableArray<EKCalendar *> *calendars = [mutableSections objectForKey:color];
        [calendars removeObjectAtIndex:indexPath.row];
        self.sections = mutableSections;
        [self.categoriesTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row
                                                                              inSection:indexPath.section]]
                                        withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.categoriesTableView endUpdates];
    
    [self.categoriesTableView setEditing:NO animated:YES];
    self.navigationItem.leftBarButtonItem.title = @"Edit";
    
    [eventManager removeCustomCalendarIdentifier:cal.calendarIdentifier];
    NSError *error;
    if (![eventManager.eventStore removeCalendar:cal commit:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        NSLog(@"Successfully deleted calendar titled %@", cal.title);
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *editAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                         title:@"Edit"
                                                                       handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                                                                           [self presentEditCategoriesVC:indexPath];
                                                                       }];
    editAction.backgroundColor = [UIColor flatGreenColor];
    
    UIContextualAction *deleteAction = [UIContextualAction
                                      contextualActionWithStyle:UIContextualActionStyleNormal
                                      title:@"Delete"
                                      handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                                          __weak CategoriesViewController *weakSelf = self;
                                          [self shouldProceedWithDeletingCalendar:^(BOOL shouldProceed) {
                                              if (shouldProceed) {
                                                  [weakSelf deleteCategoryAtIndexPath:indexPath];
                                              } else {
                                                  [weakSelf.categoriesTableView setEditing:NO animated:YES];
                                                  weakSelf.navigationItem.leftBarButtonItem.title = @"Edit";
                                              }
                                          }];
                                      }];
    deleteAction.backgroundColor = [UIColor redColor];
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, editAction]];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (void)presentEditCategoriesVC:(NSIndexPath *)indexPath {
    UIColor *color = [self.colors objectAtIndex:indexPath.section];
    NSArray *calendarsForColor = [self.sections objectForKey:color];
    EKCalendar *cal = [calendarsForColor objectAtIndex:indexPath.row];
    
    EventManager *eventManager = [EventManager sharedManager];
    NSString *colorTitle;
    for (UIColor *colorKey in eventManager.colorStrings) {
        if ([colorKey isEqualToColor:color]) {
            colorTitle = [eventManager.colorStrings objectForKey:colorKey];
        }
    }
    
    EditCategoriesViewController *editCategoriesVC = [[EditCategoriesViewController alloc] initWithCalendar:cal
                                                                                                 colorTitle:colorTitle];
    [self.navigationController pushViewController:editCategoriesVC animated:YES];
}

- (void)shouldProceedWithDeletingCalendar:(void (^)(BOOL shouldProceed))completion {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Calendar"
                                                                             message:@"Are you sure?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction *action) {
                                                         completion(NO);
                                                     }];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completion(YES);
                                                      }];
    [alertController addAction:noAction];
    [alertController addAction:yesAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIColor *color = [self.colors objectAtIndex:indexPath.section];
    NSArray *calendarsForColor = [self.sections objectForKey:color];
    EKCalendar *calendar = [calendarsForColor objectAtIndex:indexPath.row];
    
    EventsViewController *eventsViewController = [[EventsViewController alloc] initWithCalendar:calendar];
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
//        UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
//                                                                           style:UIBarButtonItemStylePlain
//                                                                          target:self
//                                                                          action:@selector(showEditing:)];
//        leftButtonItem.tintColor = [UIColor blackColor];
//        [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
//        [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
//        self.navigationItem.leftBarButtonItem = leftButtonItem;
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(pushAddCategoryVC)];
    rightButtonItem.tintColor = [UIColor blackColor];
    [rightButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    [rightButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
}

- (void)showEditing:(UIBarButtonItem *)sender {
    if (self.categoriesTableView.isEditing) {
        [self.categoriesTableView setEditing:NO animated:YES];
        self.navigationItem.leftBarButtonItem.title = @"Edit";
    } else {
        [self.categoriesTableView setEditing:YES animated:YES];
        self.navigationItem.leftBarButtonItem.title = @"Done";
    }
}

- (void)configureViewAndTableView {
    self.view.backgroundColor = [UIColor whiteColor];
//    self.categoriesTableView.backgroundColor = [UIColor clearColor];
    
    self.navigationController.navigationBar.clipsToBounds = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Load the NIB file, and register the NIB (which contains the cell)
    UINib *nib = [UINib nibWithNibName:@"CategoriesTableViewCell" bundle:nil];
    [self.categoriesTableView registerNib:nib forCellReuseIdentifier:@"CategoriesTableViewCell"];
    
    // Eliminate line separators for the UITableView
    //  self.categoriesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Insert a dummy footer view which will only show amount of cells you returned in tableView:numberOfRowsInSection:
//    self.categoriesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Do NOT modify the content area of the scroll view using the safe area insets
    if (@available(iOS 11.0, *)) {
        self.categoriesTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    self.categoriesTableView.contentInset = UIEdgeInsetsMake(-11, 0, 0, 0);
    
    // Dont let scroll view bounce past the end of the bounds
//    self.categoriesTableView.alwaysBounceVertical = NO;
}


#pragma mark - Custom Getters


- (AppDelegate *)appDelegate {
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

- (NSDictionary<UIColor *, NSArray<EKCalendar *> *> *)sections {
    if (!_sections) {
        _sections = [NSDictionary<UIColor *, NSArray<EKCalendar *> *> dictionary];
    }
    return _sections;
}


@end
