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

@property (strong, nonatomic) NSMutableDictionary<NSDate *, NSMutableArray<EKEvent *> *> *dateEvents;
@property (strong, nonatomic) NSArray<NSDate *> *sortedDays;

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
    [self setTableViewContentInset];
    [self addDataDidChangeNotificationObserver];
    
    [self loadData];
}

- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self loadEventsData];
    });
}

- (void)loadEventsData {
    EventsModel *eventsModel = [[EventsModel alloc] init];
    [eventsModel loadEventsDataWithStartDate:]
}

//- (void)loadEventsData {
//    EventManager *eventManager = [EventManager sharedManager];
//    NSDate *startDate = [[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]];
//    //    NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow:[[NSDate distantFuture] timeIntervalSinceReferenceDate]];
//
//    NSDateComponents *comps = [NSDateComponents new];
//    comps.year = 1;
//    NSDate *compsDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:startDate options:0];
//
//    NSDate *endDate = [[NSCalendar currentCalendar] startOfDayForDate:compsDate];
//
//
//    __weak EventsViewController *weakSelf = self;
//    [eventManager loadDateEventsFromStartDate:startDate
//                                      endDate:endDate
//                                     calendar:self.calendar
//                                   completion:^(NSDictionary<NSDate *, NSArray<EKEvent *> *> *dateEvents, NSArray<NSDate *> *days) {
//                                       weakSelf.dateEvents = dateEvents;
//                                       weakSelf.days = days;
//                                       [weakSelf loadTableViewData];
//                                   }];
//
//    //    NSArray *calendarArray = [NSArray arrayWithObject:self.calendar];
//    //    NSPredicate *fetchCalendarEvents = [eventManager.eventStore predicateForEventsWithStartDate:[NSDate date] endDate:endDate calendars:calendarArray];
//    //    self.events = [eventManager.eventStore eventsMatchingPredicate:fetchCalendarEvents];
//}
//
//- (void)loadTableViewData {
//    self.eventsModel = [[EventsModel alloc] initWithDateEvents:self.dateEvents days:self.days];
//    __weak EventsViewController *weakSelf = self;
//    [self.eventsModel loadEventsModelDataWithCompletion:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf refreshTableView];
//        });
//    }];
//}
//
//- (void)refreshTableView {
//    [UIView transitionWithView:self.tableView
//                      duration:0.25
//                       options:UIViewAnimationOptionTransitionCrossDissolve
//                    animations:^{
//                        [self.tableView reloadData];
//                    }
//                    completion:nil];
//}


#pragma mark - UITableViewDataSource


//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    //    return [self.eventsModel.dateEvents count];
//    return [self.eventsModel.indexedEvents count];
//
//}
//
//- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [self.eventsModel.indexedEvents[section] count];
//}
//
//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    return [self.tableViewHeaderFormatter stringFromDate:[self.eventsModel.indexedEvents[section] firstObject].startDate];
//}
//
//- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
//    EventsTableViewCell *cell = (EventsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EventsTableViewCell" forIndexPath:indexPath];
//
//    EKEvent *event = [self.eventsModel.indexedEvents[indexPath.section] objectAtIndex:indexPath.row];
//
//    cell.textLabel.text = event.calendar.title;
//    cell.textLabel.textColor = [UIColor colorWithCGColor:event.calendar.CGColor];
//
//    NSString *eventTitle = event.title.length != 0 ? event.title : @"No title";
//    NSString *startDateTitle = [self.cellDateFormatter stringFromDate:event.startDate];
//    NSString *endDateTitle = [self.cellDateFormatter stringFromDate:event.endDate];
//
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  |  %@ - %@", eventTitle, startDateTitle, endDateTitle];
//
//    return cell;
//}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dateEvents count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDate *dateRepresentingThisDay = [self.sortedDays objectAtIndex:section];
    NSArray *eventsOnThisDay = [self.dateEvents objectForKey:dateRepresentingThisDay];
    return [eventsOnThisDay count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDate *dateRepresentingThisDay = [self.sortedDays objectAtIndex:section];
    return [self.tableViewHeaderFormatter stringFromDate:dateRepresentingThisDay];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventsTableViewCell *cell = (EventsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EventsTableViewCell" forIndexPath:indexPath];
    
    NSDate *dateRepresentingThisDay = [self.sortedDays objectAtIndex:indexPath.section];
    NSArray *eventsOnThisDay = [self.dateEvents objectForKey:dateRepresentingThisDay];
    EKEvent *event = [eventsOnThisDay objectAtIndex:indexPath.row];
    
    cell.textLabel.text = event.calendar.title;
    cell.textLabel.textColor = [UIColor colorWithCGColor:event.calendar.CGColor];
    
    NSString *eventTitle = event.title.length != 0 ? event.title : @"No title";
    NSString *startDateTitle = [self.cellDateFormatter stringFromDate:event.startDate];
    NSString *endDateTitle = [self.cellDateFormatter stringFromDate:event.endDate];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  |  %@ - %@", eventTitle, startDateTitle, endDateTitle];
    
    return cell;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EKEvent *event = [self.eventsModel.indexedEvents[indexPath.section] objectAtIndex:indexPath.row];
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
        _tableViewHeaderFormatter.dateFormat = @"E, MMMM d";
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


@end
