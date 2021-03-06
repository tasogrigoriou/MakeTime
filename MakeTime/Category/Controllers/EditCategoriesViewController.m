//
//  EditCategoriesViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 7/8/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "EditCategoriesViewController.h"
#import "AppDelegate.h"
#import "CategoriesTableViewCell.h"
#import "Chameleon.h"
#import "UIColor+RBExtras.h"

@interface EditCategoriesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *editCategoriesTableView;
@property (weak, nonatomic) IBOutlet UIButton *deleteCategoryButton;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) EKCalendar *calendar;

@property (copy, nonatomic) NSString *colorTitle;

@end

@implementation EditCategoriesViewController


#pragma mark - View Lifecycle


- (instancetype)initWithCalendar:(EKCalendar *)calendar colorTitle:(NSString *)colorTitle {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.calendar = calendar;
        self.colorTitle = colorTitle;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureViewAndTableView];
    [self customizeBarButtonItems];
    [self customizeLabel];
    self.deleteCategoryButton.layer.cornerRadius = 18.0f;
    
    [self loadCalendarColors];
}

- (void)loadCalendarColors {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self mapColorTitleToIndex];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editCategoriesTableView reloadData];
        });
    });
}


#pragma mark - IBActions


- (IBAction)popViewController:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveCalendarColor:(id)sender {
    // Get the calendar that was selected from CategoriesVC
    EKCalendar *cal = self.calendar;
    EventManager *eventManager = [EventManager sharedManager];
    
    // Re-assign the calendar's color to the color indexed at the row that is selected
    UIColor *color = eventManager.calendarUIColors[self.checkedRow];
    cal.CGColor = color.CGColor;
    
    // Commit the calendar color change to the event store
    NSError *error;
    if (![eventManager.eventStore saveCalendar:cal commit:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        NSLog(@"Successfully updated %@ CGColor property", cal.title);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"calendarOrEventDataDidChange" object:nil];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)deleteCategory:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Calendar"
                                                                             message:@"Are you sure?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction *action) {
                                                         [self dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self removeCalendarHandler];
                                                      }];
    [alertController addAction:noAction];
    [alertController addAction:yesAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)removeCalendarHandler {
    NSError *error;
    EKCalendar *cal = self.calendar;
    EventManager *eventManager = [EventManager sharedManager];
    
    [eventManager removeCustomCalendarIdentifier:cal.calendarIdentifier];
    if (![eventManager.eventStore removeCalendar:cal commit:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        NSLog(@"Successfully deleted calendar titled %@", cal.title);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"calendarOrEventDataDidChange" object:nil];
    }
    
    // viewDidLoad: does NOT get called again when popping the VC...
    // however, viewWillAppear: gets called. So we reload the custom calendars in that method in CategoriesVC.
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[EventManager sharedManager] calendarStringColors] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoriesTableViewCell *cell = (CategoriesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"CategoriesTableViewCell"];
    cell.backgroundColor = [UIColor clearColor];
    
    // If the checked row is equal to our indexPath's row, assign the checkmark image to the cell
    if (self.checkedRow == indexPath.row) {
        cell.checkmarkImage.image = [UIImage imageNamed:@"checkmark.png"];
    } else {
        cell.checkmarkImage.image = nil;
    }
    
    EventManager *eventManager = [EventManager sharedManager];
    
    cell.categoriesLabel.text = eventManager.calendarStringColors[indexPath.row];
    cell.categoriesLabel.font = [UIFont fontWithName:@"Avenir Next Condensed Medium" size:15.0f];
    
    // Since we need the backgroundColor of the colorView to persist through out the highlight animation,
    // Create a CALayer with a background color, instead of using the backgroundColor property of UIView.
    UIColor *calendarColor = eventManager.calendarUIColors[indexPath.row];
    CALayer *layer = [CALayer layer];
    layer.cornerRadius = cell.categoriesColorView.bounds.size.width / 2;
    layer.frame = cell.categoriesColorView.bounds;
    layer.backgroundColor = calendarColor.CGColor;
    [cell.categoriesColorView.layer addSublayer:layer];
    
    return cell;
}


#pragma  mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Assign our checkedRow value to be the value of the row in the table view
    self.checkedRow = indexPath.row;
    
    [UIView transitionWithView:tableView
                      duration:0.30f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        [tableView reloadData];
                    }
                    completion:nil];
}


#pragma mark - Private Methods


- (void)customizeLabel {
    EKCalendar *cal = self.calendar;
    
    // Assign the nav bar's title to be the title of the selected calendar
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor colorWithCGColor:cal.CGColor];
    label.text = cal.title;
    [label sizeToFit];
    self.navigationItem.titleView = label;
}

- (void)configureViewAndTableView {
    self.navigationController.navigationBar.clipsToBounds = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Load the NIB file, and register the NIB (which contains the cell)
    UINib *nib = [UINib nibWithNibName:@"CategoriesTableViewCell" bundle:nil];
    [self.editCategoriesTableView registerNib:nib forCellReuseIdentifier:@"CategoriesTableViewCell"];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.editCategoriesTableView.backgroundColor = [UIColor clearColor];
    
    // Insert a dummy footer view to limit the tableview to only show the amount of cells returned in data source method
    self.editCategoriesTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Dont let scroll view bounce past the end of the bounds
    self.editCategoriesTableView.alwaysBounceVertical = NO;
    
    // Do NOT modify the content area of the scroll view using the safe area insets
    if (@available(iOS 11.0, *)) {
        self.editCategoriesTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

- (void)customizeBarButtonItems
{
    // Give the delete button a border
    //   self.deleteCategoryButton.layer.cornerRadius = 1.0f;
    //   self.deleteCategoryButton.layer.borderWidth = 0.7f;
    //   self.deleteCategoryButton.layer.borderColor = [UIColor lightGrayHTMLColor].CGColor;
    
    // Assign a cancel button on the left side of the nav bar
    UIBarButtonItem *cancelBBI = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(popViewController:)];
    [cancelBBI
     setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"Avenir Next Condensed Medium" size:14.0],
                               NSForegroundColorAttributeName : [UIColor blackColor] } forState:UIControlStateNormal];
    cancelBBI.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = cancelBBI;
    
    // Assign a save button on the right side of the nav bar
    UIBarButtonItem *saveBBI = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(saveCalendarColor:)];
    [saveBBI
     setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"Avenir Next Condensed Medium" size:14.0],
                               NSForegroundColorAttributeName : [UIColor blackColor] } forState:UIControlStateNormal];
    saveBBI.tintColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = saveBBI;
}

- (void)mapColorTitleToIndex {
    EventManager *eventManager = [EventManager sharedManager];
    for (NSInteger i = 0; i < eventManager.calendarStringColors.count; i++) {
        NSString *stringColor = eventManager.calendarStringColors[i];
        if ([stringColor isEqualToString:self.colorTitle]) {
            self.checkedRow = i;
        }
    }
}


@end
