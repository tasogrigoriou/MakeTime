//
//  AddCalendarViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/23/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "AddCalendarViewController.h"
#import "AppDelegate.h"
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


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureLabels];
    [self configureViewAndTableView];
    [self configureBarButtonItems];
    [self addTapGestureRecognizer];
    
    [self loadCalendarData];
    
    // Dummy value to avoid a checked row when first loading the view
    self.checkedRow = 100;
}

- (void)loadCalendarData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        __weak AddCalendarViewController *weakSelf = self;
        [[EventManager sharedManager] loadCustomCalendarsWithCompletion:^(NSArray *calendars) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.customCalendars = calendars;
                [weakSelf.addCalendarTableView reloadData];
            });
        }];
    });
}


#pragma mark - UITextFieldDelegate


// The text field calls this method whenever the user taps the return button.
// Use this method to implement any custom behavior when return is tapped (MUST make sure delegate is set in XIB).
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - Selectors


- (void)popViewController:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveCalendar:(id)sender {
    EventManager *eventManager = [EventManager sharedManager];
    // Create a new calendar with a title, source, and color
    EKCalendar *newCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent
                                                     eventStore:eventManager.eventStore];
    newCalendar.title = self.categoryTextField.text;
    BOOL isiCloud = NO;
    for (EKSource *source in eventManager.eventStore.sources) {
        if (source.sourceType == EKSourceTypeCalDAV && [source.title isEqualToString:@"iCloud"]) {
            if ([source calendarsForEntityType:EKEntityTypeEvent].count > 0) {
                newCalendar.source = source;
                isiCloud = YES;
                break;
            }
        }
    }
    if (!isiCloud) {
        if (![eventManager.eventStore.defaultCalendarForNewEvents.source.title containsString:@"gmail.com"]) {
            newCalendar.source = eventManager.eventStore.defaultCalendarForNewEvents.source;
        } else {
            for (EKSource *source in eventManager.eventStore.sources) {
                if (source.sourceType == EKSourceTypeLocal) {
                    newCalendar.source = source;
                    break;
                }
            }
        }
    }
    
//    newCalendar.source = eventManager.eventStore.defaultCalendarForNewEvents.source;
    
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
        UIColor *color = eventManager.calendarUIColors[self.checkedRow];
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
    if (![eventManager.eventStore saveCalendar:newCalendar commit:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        NSLog(@"Successfully saved calendar - %@", newCalendar.title);
        [eventManager saveCustomCalendarIdentifier:newCalendar.calendarIdentifier];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"calendarOrEventDataDidChange" object:nil];
    }
    
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
    cell.categoriesLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0f];
    
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


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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


- (void)configureLabels {
    // Customize title on nav bar
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.text = @"New Category";
    [label sizeToFit];
    self.navigationItem.titleView = label;
    
    // Override font to match font of "Color" in the table view
    self.categoryLabel.font = [UIFont fontWithName:@"Avenir Next Condensed Ultra Light" size:15.0f];
    self.categoryLabel.layer.opacity = 0.7;
}

- (void)configureBarButtonItems {
    
    //    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    //    button.bounds = CGRectMake(0, 0, 24.0, 24.0);
    //    button.tintColor = [UIColor blackColor];
    //    [button setImage:[UIImage imageNamed:@"backarrow2"] forState:UIControlStateNormal];
    //    [button addTarget:self action:@selector(popViewController:) forControlEvents:UIControlEventTouchUpInside];
    //    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    //    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    NSDictionary *textAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:14.0], NSForegroundColorAttributeName : [UIColor blackColor] };
    
    UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"backarrow2"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(popViewController:)];
    leftButtonItem.tintColor = [UIColor blackColor];
    [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(saveCalendar:)];
    [saveButton setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    [saveButton setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    saveButton.tintColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)configureViewAndTableView {
    self.navigationController.navigationBar.clipsToBounds = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Load the NIB file, and register the NIB (which contains the cell)
    UINib *nib = [UINib nibWithNibName:@"CategoriesTableViewCell" bundle:nil];
    [self.addCalendarTableView registerNib:nib forCellReuseIdentifier:@"CategoriesTableViewCell"];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.addCalendarTableView.backgroundColor = [UIColor clearColor];
    
    // Insert a dummy footer view.
    // This will limit the tableview to only show the amount of cells you returned in tableView:numberOfRowsInSection:
    self.addCalendarTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Do NOT modify the content area of the scroll view using the safe area insets
    if (@available(iOS 11.0, *)) {
        self.addCalendarTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

- (void)addTapGestureRecognizer {
    // Add a gesture recognizer and assign it to the view,
    // then call endEditing: action method to have the UITextField resign first responder status when screen is touched.
    // Make sure the gesture recognizer doesn't intercept taps on the view by assigning NO to cancelsTouches property
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self.view action:@selector(endEditing:)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGestureRecognizer];
}


@end
