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
@property (strong, nonatomic) NSArray *customCalendars;

@end

@implementation EditCategoriesViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
   [super viewDidLoad];
   
   [self customizeLabel];
   [self configureViewAndTableView];
   [self customizeBarButtonItems];
   
    [self loadCalendarData];
}

- (void)loadCalendarData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self assignCalendarColors];
        });
        [[EventManager sharedManager] loadCustomCalendars];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.customCalendars = [[EventManager sharedManager] customCalendars];
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
   EKCalendar *cal = self.customCalendars[self.indexOfCategory];
   
   // Re-assign the calendar's color to the color indexed at the row that is selected
   UIColor *color = self.calendarUIColors[self.checkedRow];
   cal.CGColor = color.CGColor;
   
   // Commit the calendar color change to the event store
   NSError *error;
   if (![[[EventManager sharedManager] eventStore] saveCalendar:cal commit:YES error:&error]) {
      NSLog(@"%@", [error localizedDescription]);
   } else NSLog(@"Successfully updated %@ CGColor property", cal.title);
   
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
   EKCalendar *cal = self.customCalendars[self.indexOfCategory];
    EventManager *eventManager = [EventManager sharedManager];
    
   [eventManager removeCustomCalendarIdentifier:cal.calendarIdentifier];
   if (![eventManager.eventStore removeCalendar:cal commit:YES error:&error]) {
      NSLog(@"%@", [error localizedDescription]);
   } else {
      NSLog(@"Successfully deleted calendar titled %@", cal.title);
   }
   
   // viewDidLoad: does NOT get called again when popping the VC...
   // however, viewWillAppear: gets called. So we reload the custom calendars in that method in CategoriesVC.
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
   
   // Since we need the backgroundColor of the colorView to persist through out the highlight animation,
   // Create a CALayer with a background color, instead of using the backgroundColor property of UIView.
   UIColor *calendarColor = self.calendarUIColors[indexPath.row];
   CALayer *layer = [CALayer layer];
    layer.cornerRadius = cell.categoriesColorView.bounds.size.width / 2;
   layer.frame = cell.categoriesColorView.bounds;
   layer.backgroundColor = calendarColor.CGColor;
   [cell.categoriesColorView.layer addSublayer:layer];
   
   return cell;
}


#pragma  mark - UITableViewDelegate


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


#pragma mark - Private Methods


- (void)customizeLabel
{
   EKCalendar *cal = self.customCalendars[self.indexOfCategory];
   
   // Assign the nav bar's title to be the title of the selected calendar
   UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
   label.backgroundColor = [UIColor clearColor];
   label.font = [UIFont fontWithName:@"Avenir Next Condensed Regular" size:14.0f];
   label.textAlignment = NSTextAlignmentCenter;
   label.textColor = [UIColor colorWithCGColor:cal.CGColor];
   label.text = cal.title;
   [label sizeToFit];
   self.navigationItem.titleView = label;
}

- (void)configureViewAndTableView
{
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


@end
