//
//  EventsViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/13/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "EventsViewController.h"
#import "EventManager.h"
#import "EventsModel.h"
#import "EventsTableViewCell.h"
#import "EditEventViewController.h"

@interface EventsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) EventsModel *eventsModel;

@property (strong, nonatomic) EKCalendar *calendar;

//@property (strong, nonatomic) NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents;
@property (strong, nonatomic) NSArray<NSDate *> *days;

@property (strong, nonatomic) NSDateFormatter *headerFormatter;
@property (strong, nonatomic) NSDateFormatter *tableViewHeaderFormatter;
@property (strong, nonatomic) NSDateFormatter *cellDateFormatter;

//@property (strong, nonatomic) NSMutableDictionary<NSDate *, NSMutableArray<EKEvent *> *> *dateEvents;
//@property (strong, nonatomic) NSArray<NSDate *> *sortedDays;

@end


@implementation EventsViewController


#pragma mark - View Lifecycle


- (instancetype)initWithCalendar:(EKCalendar *)calendar {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.calendar = calendar;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureViewAndCalendarView];
    [self customizeNavBarTitle];
    [self customizeLeftBarButtonItem];
    [self setTableViewContentInset];
    [self addDataDidChangeNotificationObserver];
    
    [self loadData];
}


#pragma mark - Loading Data


- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self loadEventsData];
    });
}

- (void)loadEventsData {
    NSDate *startDate = [NSDate date];
    NSDateComponents *comps = [NSDateComponents new];
    comps.year = 1;
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:startDate options:0];
    
    __weak EventsViewController *weakSelf = self;
    [self.eventsModel loadEventsDataModelWithStartDate:startDate endDate:endDate calendars:@[self.calendar] completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    }];
}


#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.eventsModel.dateEvents count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDate *dateRepresentingThisDay = [self.eventsModel.sortedDays objectAtIndex:section];
    NSArray *eventsOnThisDay = [self.eventsModel.dateEvents objectForKey:dateRepresentingThisDay];
    return [eventsOnThisDay count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDate *dateRepresentingThisDay = [self.eventsModel.sortedDays objectAtIndex:section];
    return [self.tableViewHeaderFormatter stringFromDate:dateRepresentingThisDay];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventsTableViewCell *cell = (EventsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EventsTableViewCell"
                                                                                       forIndexPath:indexPath];
    
    NSDate *dateRepresentingThisDay = [self.eventsModel.sortedDays objectAtIndex:indexPath.section];
    NSArray *eventsOnThisDay = [self.eventsModel.dateEvents objectForKey:dateRepresentingThisDay];
    EKEvent *event = [eventsOnThisDay objectAtIndex:indexPath.row];
    
    NSString *eventTitle = event.title.length != 0 ? event.title : @"No title";
    
    cell.textLabel.text = eventTitle;
//    cell.textLabel.textColor = [UIColor colorWithCGColor:event.calendar.CGColor];
    
    NSString *startDateTitle = [self.cellDateFormatter stringFromDate:event.startDate];
    NSString *endDateTitle = [self.cellDateFormatter stringFromDate:event.endDate];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", startDateTitle, endDateTitle];
    
    return cell;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDate *dateRepresentingThisDay = [self.eventsModel.sortedDays objectAtIndex:indexPath.section];
    NSArray *eventsOnThisDay = [self.eventsModel.dateEvents objectForKey:dateRepresentingThisDay];
    EKEvent *event = [eventsOnThisDay objectAtIndex:indexPath.row];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[EditEventViewController alloc] initWithEvent:event]];
    [self presentViewController:navController animated:YES completion:^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}


#pragma mark - Private Methods


- (void)configureViewAndCalendarView {
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EventsTableViewCell" bundle:nil] forCellReuseIdentifier:@"EventsTableViewCell"];
    
//    [self.tableView setHidden:YES duration:0.0 completion:nil];
}

- (void)setTableViewContentInset {
    self.tableView.contentInset = UIEdgeInsetsMake(-7, 0, 0, 0);
}

- (void)customizeNavBarTitle {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor colorWithCGColor:self.calendar.CGColor];
    label.text = [NSString stringWithFormat:@"%@ Events", self.calendar.title];
    [label sizeToFit];
    self.navigationItem.titleView = label;
}

- (void)customizeLeftBarButtonItem {
    UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"backarrow2"]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(popViewController:)];
    leftButtonItem.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
}

- (void)popViewController:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addDataDidChangeNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataDidChange)
                                                 name:@"calendarOrEventDataDidChange"
                                               object:nil];
}

- (void)dataDidChange {
    [self loadData];
}


#pragma mark - Custom Getters


- (NSDateFormatter *)headerFormatter {
    if (!_headerFormatter) {
        _headerFormatter = [NSDateFormatter new];
        _headerFormatter.locale = [NSLocale currentLocale];
        _headerFormatter.dateFormat = @"MMMM, yyyy";
    }
    return _headerFormatter;
}

- (NSDateFormatter *)tableViewHeaderFormatter {
    if (!_tableViewHeaderFormatter) {
        _tableViewHeaderFormatter = [NSDateFormatter new];
        _tableViewHeaderFormatter.locale = [NSLocale currentLocale];
        _tableViewHeaderFormatter.dateFormat = @"E, MMMM d, yyyy";
    }
    return _tableViewHeaderFormatter;
}

- (NSDateFormatter *)cellDateFormatter {
    if (!_cellDateFormatter) {
        _cellDateFormatter = [NSDateFormatter new];
        _cellDateFormatter.locale = [NSLocale currentLocale];
        _cellDateFormatter.dateFormat = @"h:mm a";
    }
    return _cellDateFormatter;
}

- (EventsModel *)eventsModel {
    if (!_eventsModel) {
        _eventsModel = [[EventsModel alloc] init];
    }
    return _eventsModel;
}


@end
