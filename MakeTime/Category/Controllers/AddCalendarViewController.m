//
//  AddCalendarViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/23/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "AddCalendarViewController.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "CategoriesTableViewCell.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "SwipeBack.h"

@interface AddCalendarViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UITextField *categoryTextField;

@property (weak, nonatomic) IBOutlet UITableView *addCalendarTableView;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;

@end

@implementation AddCalendarViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self configureLabels];
    [self configureViewAndTableView];
    [self configureBarButtonItems];
    [self giveGradientBackgroundColor];
    [self addTapGestureRecognizer];

    // Get a ref to the app delegate, load our custom categories,
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.customCalendars = [self.appDelegate.eventManager loadCustomCalendars];

    // Assign calendarColors as UIColors and as NSStrings for the labels
    [self assignCalendarColors];

    // Dummy value to avoid a checked row when first loading the view
    self.checkedRow = 100;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // disable swipe when view is added to hierarchy
    self.revealViewController.panGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // re-enable swipe when view is removed from hierarchy
    self.revealViewController.panGestureRecognizer.enabled = YES;
}


#pragma mark - UITextFieldDelegate


// The text field calls this method whenever the user taps the return button.
// Use this method to implement any custom behavior when return is tapped (MUST make sure delegate is set in XIB).
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - Selectors


- (void)popViewController:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveCalendar:(id)sender
{
    // Create a new calendar with a title, source, and color
    EKCalendar *newCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent
                                                     eventStore:self.appDelegate.eventManager.eventStore];
    newCalendar.title = self.categoryTextField.text;
    newCalendar.source = self.appDelegate.eventManager.eventStore.defaultCalendarForNewEvents.source;

    // Trim whitespace and newline into a new NSString to check for an empty calendar title
    NSString *trimmedTitle = [newCalendar.title
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([trimmedTitle isEqualToString:@""]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"This category doesn't have a title"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    // Check if a color was selected before assigning the newCalendar's color property
    if (self.checkedRow == 100) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"This category doesn't have a color"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    } else {
        UIColor *color = self.calendarUIColors[self.checkedRow];
        newCalendar.CGColor = color.CGColor;
    }

    // If the new calendar has the same title as one of our custom calendars, show an alert action message
    for (EKCalendar *cal in self.customCalendars) {
        if ([[cal.title uppercaseString] isEqualToString:[newCalendar.title uppercaseString]]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"This category already exists"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {}];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
    }

    // Save and commit the calendar to the event store and save its calendar identifier to NSUserDefaults.
    NSError *error;
    if (![self.appDelegate.eventManager.eventStore saveCalendar:newCalendar commit:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        NSLog(@"Successfully saved calendar - %@", newCalendar.title);
        [self.appDelegate.eventManager saveCustomCalendarIdentifier:newCalendar.calendarIdentifier];
    }

    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.calendarStringColors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CategoriesTableViewCell *cell = (CategoriesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"CategoriesTableViewCell"];
    cell.backgroundColor = [UIColor clearColor];

    // If the checked row is equal to our indexPath's row, assign the checkmark image to the cell
    if (self.checkedRow == indexPath.row) {
        cell.checkmarkImage.image = [UIImage imageNamed:@"checkmark.png"];
    } else {
        cell.checkmarkImage.image = nil;
    }

    cell.categoriesLabel.text = self.calendarStringColors[indexPath.row];
    cell.categoriesLabel.font = [UIFont fontWithName:@"Avenir Next Condensed Medium" size:15.0f];
    cell.categoriesColorView.backgroundColor = self.calendarUIColors[indexPath.row];
    cell.categoriesColorView.layer.cornerRadius = 6.0f;

    return cell;
}

// Create custom view to display section header
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 33)];

    // Create a horizontal, dark gray line and insert it as a subview of our custom headerView.
    //  UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, self.view.frame.size.width, 0.30)];
    //  lineView.backgroundColor = [UIColor lightGrayColor];
    //  [view addSubview:lineView];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, tableView.frame.size.width, 36)];
    label.font = [UIFont fontWithName:@"Avenir Next Condensed Ultra Light" size:15.0f];
    label.layer.opacity = 0.7;
    label.text = @"Color";
    [view addSubview:label];

    return view;
}

// Method required for tableView:viewForHeaderInSection: to work
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
{
    return 33.0f;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Assign our checkedRow value to be the value of the row in the table view
    self.checkedRow = indexPath.row;

    [UIView transitionWithView:tableView
                      duration:0.30f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
                        [tableView reloadData];
                    }
                    completion:nil];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingFooterView:(UIView *)view forSection:(NSInteger)section {
}


#pragma mark - Private Methods


- (void)configureLabels
{
    // Customize title on nav bar
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Avenir Next Condensed Regular" size:13.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.text = @"New Category";
    [label sizeToFit];
    self.navigationItem.titleView = label;

    // Override font to match font of "Color" in the table view
    self.categoryLabel.font = [UIFont fontWithName:@"Avenir Next Condensed Ultra Light" size:15.0f];
    self.categoryLabel.layer.opacity = 0.7;
}

- (void)configureBarButtonItems
{
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
                                                               action:@selector(saveCalendar:)];
    [saveBBI
            setTitleTextAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"Avenir Next Condensed Medium" size:14.0],
                    NSForegroundColorAttributeName : [UIColor blackColor] } forState:UIControlStateNormal];
    saveBBI.tintColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = saveBBI;

    self.navigationController.swipeBackEnabled = NO;
}

- (void)configureViewAndTableView
{
    self.navigationController.navigationBar.clipsToBounds = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;

    // Load the NIB file, and register the NIB (which contains the cell)
    UINib *nib = [UINib nibWithNibName:@"CategoriesTableViewCell" bundle:nil];
    [self.addCalendarTableView registerNib:nib forCellReuseIdentifier:@"CategoriesTableViewCell"];

    self.view.backgroundColor = [UIColor clearColor];
    self.addCalendarTableView.backgroundColor = [UIColor clearColor];

    // Insert a dummy footer view.
    // This will limit the tableview to only show the amount of cells you returned in tableView:numberOfRowsInSection:
    self.addCalendarTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    // Do NOT modify the content area of the scroll view using the safe area insets
    if (@available(iOS 11.0, *)) {
        self.addCalendarTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

- (void)giveGradientBackgroundColor
{
    // Create an overlay view to give a gradient background color
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 3000);
    UIView *overlayView = [[UIView alloc] initWithFrame:frame];
    UIColor *skyBlueLight = [UIColor colorWithHue:0.57 saturation:0.90 brightness:0.98 alpha:1.0];
    overlayView.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom
                                                        withFrame:frame
                                                        andColors:@[[UIColor whiteColor], skyBlueLight]];
    [self.view insertSubview:overlayView atIndex:0];
}

- (void)assignCalendarColors
{
    UIColor *hotPink = [UIColor colorWithRed:(238/255.0) green:(106/255.0) blue:(167/255.0) alpha:1.0];
    UIColor *turquoise = [UIColor colorWithRed:(64/255.0) green:(224/255.0) blue:(208/255.0) alpha:1.0];
    UIColor *darkOrchid = [UIColor colorWithRed:(154/255.0) green:(50/255.0) blue:(205/255.0) alpha:1.0];
    UIColor *darkOrange = [UIColor colorWithRed:(255/255.0) green:(140/255.0) blue:(0/255.0) alpha:1.0];
    UIColor *chartreuse = [UIColor colorWithRed:(118/255.0) green:(238/255.0) blue:(0/255.0) alpha:1.0];
    UIColor *yellow = [UIColor colorWithRed:(238/255.0) green:(238/255.0) blue:(0/255.0) alpha:1.0];

    self.calendarUIColors = @[hotPink, turquoise, darkOrchid, darkOrange, chartreuse, yellow];
    self.calendarStringColors = @[@"Pink", @"Turquoise", @"Orchid", @"Orange", @"Chartreuse", @"Yellow"];
}

- (void)addTapGestureRecognizer
{
    // Add a gesture recognizer and assign it to the view,
    // then call endEditing: action method to have the UITextField resign first responder status when screen is touched.
    // Make sure the gesture recognizer doesn't intercept taps on the view by assigning NO to cancelsTouches property
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
            initWithTarget:self.view action:@selector(endEditing:)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGestureRecognizer];
}


@end
