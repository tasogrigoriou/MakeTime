//
//  RepeatAlertViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 7/29/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "RepeatAlertViewController.h"
#import "SwipeBack.h"
#import "CategoriesTableViewCell.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"

@interface RepeatAlertViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *repeatAlertTableView;

@property (strong, nonatomic) NSArray *repeatOptions;
@property (strong, nonatomic) NSArray *alarmOptions;

@end

@implementation RepeatAlertViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
   [super viewDidLoad];
   
   [self configureViewAndTableView];
   
   [self customizeNavBarTitle];
   [self customizeLeftBarButtonItem];
   
   self.repeatOptions = @[@"Never", @"Every day", @"Every week", @"Every month", @"Every year"];
   self.alarmOptions = @[@"None", @"At time of event", @"5 minutes before", @"10 minutes before", @"30 minutes before", @"1 hour before", @"1 day before"];
   
   // Call delegate method here to ensure that when we push the RepeatAlertVC, the boolean gets assigned to YES.
   [self.delegate didPushRepeatAlertViewController:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
        [self.repeatAlertTableView layoutIfNeeded];
        [self.repeatAlertTableView reloadData];
    });
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   if ([self.repeatOrAlarm isEqualToString:@"Repeat"]) {
      return [self.repeatOptions count];
   } else {
      return [self.alarmOptions count];
   }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   CategoriesTableViewCell *cell = (CategoriesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"CategoriesTableViewCell"];
   cell.backgroundColor = [UIColor clearColor];
   cell.categoriesLabel.font = [UIFont fontWithName:@"Avenir Next Condensed Medium" size:15.0f];
   
   if ([self.repeatOrAlarm isEqualToString:@"Repeat"]) {
      
      cell.categoriesLabel.text = self.repeatOptions[indexPath.row];
      if (self.checkedRowForRepeat == indexPath.row) {
         cell.checkmarkImage.image = [UIImage imageNamed:@"checkmark.png"];
      } else {
         cell.checkmarkImage.image = nil;
      }
      
   } else {
      
      cell.categoriesLabel.text = self.alarmOptions[indexPath.row];
      if (self.checkedRowForAlarm == indexPath.row) {
         cell.checkmarkImage.image = [UIImage imageNamed:@"checkmark.png"];
      } else {
         cell.checkmarkImage.image = nil;
      }
   }
   
   return cell;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   if ([self.repeatOrAlarm isEqualToString:@"Repeat"]) {
      [self.delegate didSelectRepeatOption:indexPath.row];
      self.checkedRowForRepeat = indexPath.row;
   } else {
      [self.delegate didSelectAlarmOption:indexPath.row];
      self.checkedRowForAlarm = indexPath.row;
   }
   
   [self.navigationController popViewControllerAnimated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    // recast your view as a UITableViewHeaderFooterView
//    UITableViewHeaderFooterView *header = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 10)];
    UITableViewHeaderFooterView *header = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectZero];
//    header.backgroundColor = [UIColor whiteColor];
//    header.backgroundView.backgroundColor = [UIColor whiteColor];
//    header.contentView.backgroundColor = [UIColor whiteColor];
    header.textLabel.textColor = [UIColor blackColor];
//    [header.textLabel setFont:[UIFont fontWithName:@"Rubik-Regular" size:10.0]];
//    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height, header.frame.size.width, 0.5)];
//    [separator setBackgroundColor:[UIColor lightGrayColor]];
//    [header addSubview:separator];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}


#pragma mark - Selectors


- (void)popViewController:(id)sender {
   [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Custom Methods


- (void)configureViewAndTableView {
   self.navigationController.navigationBar.clipsToBounds = NO;
   self.automaticallyAdjustsScrollViewInsets = NO;
   
   // Load the NIB file, and register the NIB (which contains the cell)
   UINib *nib = [UINib nibWithNibName:@"CategoriesTableViewCell" bundle:nil];
   [self.repeatAlertTableView registerNib:nib forCellReuseIdentifier:@"CategoriesTableViewCell"];
   
   self.view.backgroundColor = [UIColor whiteColor];
   self.repeatAlertTableView.backgroundColor = [UIColor clearColor];
   
   // Insert a dummy footer view which will only show amount of cells you returned in tableView:numberOfRowsInSection:
//   self.repeatAlertTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
   
   // Do NOT modify the content area of the scroll view using the safe area insets
   if (@available(iOS 11.0, *)) {
      self.repeatAlertTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
   }
}

- (void)customizeNavBarTitle {
   UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
   label.backgroundColor = [UIColor clearColor];
   label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0f];
   label.textAlignment = NSTextAlignmentCenter;
   label.textColor = [UIColor blackColor];
   
   if ([self.repeatOrAlarm isEqualToString:@"Repeat"]) label.text = @"Repeat Options";
   else label.text = @"Alarm Options";
   
   [label sizeToFit];
   self.navigationItem.titleView = label;
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

- (void)customizeLeftBarButtonItem {
   UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"backarrow2"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(popViewController:)];
   leftButtonItem.tintColor = [UIColor blackColor];
   self.navigationItem.leftBarButtonItem = leftButtonItem;
   self.navigationController.swipeBackEnabled = YES;
}


@end
