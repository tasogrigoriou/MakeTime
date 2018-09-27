//
//  AddEventViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/7/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import "EditEventViewController.h"
#import "TodayViewController.h"
#import "UIColor+RBExtras.h"
#import "Chameleon.h"
#import "AppDelegate.h"
#import "EventKit/EventKit.h"
#import "CalendarViewController.h"
#import "SwipeBack.h"
#import "EventTableViewCell.h"
#import "EventTextFieldTableViewCell.h"
#import "DatePickerTableViewCell.h"
#import "RepeatAlertViewController.h"
#import "CategoriesViewController.h"

@interface EditEventViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, RepeatAlertViewControllerDelegate, CategoriesViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *editEventTableView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSArray *customCalendars;

@property (strong, nonatomic) NSArray *repeatOptions;
@property (strong, nonatomic) NSArray *alarmOptions;

@property (strong, nonatomic) NSString *textFieldTitle;

@property (assign, nonatomic) BOOL isDatePickerShowing;
@property (assign, nonatomic) BOOL textFieldHasTitle;
@property (assign, nonatomic) BOOL isTextFieldTapped;
@property (assign, nonatomic) BOOL eventHasRepeat;
@property (assign, nonatomic) BOOL eventHasAlarm;

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

// Since we need to know whether a date picker is shown, and where it is, add a property to achieve these tasks:
@property (strong, nonatomic) NSIndexPath *datePickerIndexPath;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) UITextField *textField;

@end


@implementation EditEventViewController


#pragma mark - View Lifecycle


- (instancetype)initWithEvent:(EKEvent *)event {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.currentEvent = event;
        self.eventTitle = event.title;
        self.eventStartDate = event.startDate;
        self.eventEndDate = event.endDate;
        self.eventCalendar = event.calendar;
        
        self.textFieldHasTitle = YES;
        self.textFieldTitle = event.title;
        
        if (event.hasRecurrenceRules) {
            self.eventHasRepeat = YES;
            
            for (EKRecurrenceRule *rule in event.recurrenceRules) {
                if (rule.frequency == EKRecurrenceFrequencyDaily) {
                    self.repeatString = @"Every day";
                    self.repeatIndex = 1;
                }
                else if (rule.frequency == EKRecurrenceFrequencyWeekly) {
                    self.repeatString = @"Every week";
                    self.repeatIndex = 2;
                }
                else if (rule.frequency == EKRecurrenceFrequencyMonthly) {
                    self.repeatString = @"Every month";
                    self.repeatIndex = 3;
                }
                else if (rule.frequency == EKRecurrenceFrequencyYearly) {
                    self.repeatString = @"Every year";
                    self.repeatIndex = 4;
                }
            }
        }
        
        if (event.hasAlarms) {
            self.eventHasAlarm = YES;
            
            for (EKAlarm *alarm in event.alarms) {
                if (alarm.relativeOffset == 0.0) {
                    self.alarmString = @"At time of event";
                    self.alarmIndex = 1;
                }
                else if (alarm.relativeOffset == -300.0) {
                    self.alarmString = @"5 minutes before";
                    self.alarmIndex = 2;
                }
                else if (alarm.relativeOffset == -600.0) {
                    self.alarmString = @"10 minutes before";
                    self.alarmIndex = 3;
                }
                else if (alarm.relativeOffset == -1800.0) {
                    self.alarmString = @"30 minutes before";
                    self.alarmIndex = 4;
                }
                else if (alarm.relativeOffset == -3600.0) {
                    self.alarmString = @"1 hour before";
                    self.alarmIndex = 5;
                }
                else if (alarm.relativeOffset == -86400.0) {
                    self.alarmString = @"1 day before";
                    self.alarmIndex = 6;
                }
            }
        }
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureViewAndEventTableView];
    
    [self loadData];
    
    [self customizeTitle];
    [self customizeBarButtonItems];
    self.deleteButton.layer.cornerRadius = 18.0f;
    
    [self registerCellSubclasses];
    [self addTapGestureRecognizer];
}

- (void)loadData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self customizeDatesAndOptions];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.editEventTableView reloadData];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.repeatString) {
        self.eventHasRepeat = YES;
    }
    if (self.alarmString) {
        self.eventHasAlarm = YES;
    }
    
    [self.editEventTableView reloadData];
}


#pragma mark - UITextFieldDelegate


// The text field calls this method whenever the user taps the return button.
// Use this method to implement any custom behavior when return is tapped (MUST make sure delegate is set in XIB).
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length != 0) {
        self.textFieldHasTitle = YES;
        self.textFieldTitle = textField.text;
    }
    [textField resignFirstResponder];
    [self.editEventTableView reloadData];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason {
    if (textField.text.length != 0) {
        self.textFieldHasTitle = YES;
        self.textFieldTitle = textField.text;
        self.eventTitle = self.textFieldTitle;
    }
    [self.editEventTableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.textField = textField;
    self.isTextFieldTapped = YES;
    self.didPushRepeatAlertVC = NO;
    
    if (self.textFieldHasTitle) {
        self.textFieldHasTitle = NO;
        [self.editEventTableView reloadData];
    }
    
    [self.editEventTableView beginUpdates];
    if (self.datePickerIndexPath) {
        [self.editEventTableView deleteRowsAtIndexPaths:@[self.datePickerIndexPath]
                                       withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
    }
    [self.editEventTableView endUpdates];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.text = self.textFieldTitle;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}


#pragma mark - IBActions

- (IBAction)deleteEventButtonPressed:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Event"
                                                                             message:@"Are you sure?"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDestructive
                                                     handler:^(UIAlertAction *action) {
                                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [self removeEventAndDismissVC];
                                                      }];
    [alertController addAction:noAction];
    [alertController addAction:yesAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}


#pragma mark - Selectors


- (void)popViewController:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveEvent:(id)sender {
    EventManager *eventManager = [EventManager sharedManager];
    NSError *error;
    
    // Only delete the original event when user wants to edit the event and save the updates.
    if (![eventManager.eventStore removeEvent:self.currentEvent span:EKSpanFutureEvents error:&error]) {
        NSLog(@"error = %@", [error localizedDescription]);
    } else {
        NSLog(@"Successfully removed event");
    }
    
    // To create an EKEvent, we need a title, start date, end date, and a calendar
    EKEvent *event = [EKEvent eventWithEventStore:eventManager.eventStore];
    if (self.textField.text.length != 0) {
        event.title = self.textField.text;
    } else if (self.eventTitle.length != 0) {
        event.title = self.eventTitle;
    }
    event.startDate = self.eventStartDate;
    event.endDate = self.eventEndDate;
    event.calendar = self.eventCalendar;
    
    // Specify the recurrence frequency and interval values based on the repeat index in the tableview
    EKRecurrenceFrequency frequency;
    NSInteger interval;
    
    switch (self.repeatIndex) {
        case 1: interval = 1; frequency = EKRecurrenceFrequencyDaily; break;
        case 2: interval = 1; frequency = EKRecurrenceFrequencyWeekly; break;
        case 3: interval = 1; frequency = EKRecurrenceFrequencyMonthly; break;
        case 4: interval = 1; frequency = EKRecurrenceFrequencyYearly; break;
        default: interval = 0; frequency = EKRecurrenceFrequencyDaily; break;
    }
    
    // Create a rule and assign it to the reminder object if the interval is greater than 0.
    if (interval > 0) {
        EKRecurrenceEnd *recurrenceEnd = [EKRecurrenceEnd recurrenceEndWithOccurrenceCount:53];
        EKRecurrenceRule *rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:frequency
                                                                              interval:interval
                                                                                   end:recurrenceEnd];
        event.recurrenceRules = @[rule];
    } else {
        event.recurrenceRules = nil;
    }
    
    // Create a time interval and offset values based on our alarm options array
    NSTimeInterval timeInterval;
    BOOL wantsAlarm = YES;
    
    switch (self.alarmIndex) {
        case 1: timeInterval = 0.0; break;
        case 2: timeInterval = -300.0; break;
        case 3: timeInterval = -600.0; break;
        case 4: timeInterval = -1800.0; break;
        case 5: timeInterval = -3600.0; break;
        case 6: timeInterval = -86400.0; break;
        default: timeInterval = 0.0; wantsAlarm = NO; break;
    }
    
    if (wantsAlarm) {
        EKAlarm *alarm = [EKAlarm alarmWithRelativeOffset:timeInterval];
        [event addAlarm:alarm];
    }
    
    // Save event to the event store and push TodayVC on nav controller.
    if (![eventManager.eventStore saveEvent:event span:EKSpanFutureEvents commit:YES error:&error]) {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        NSLog(@"Successfully saved event %@", event);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"calendarOrEventDataDidChange" object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)removeEventAndDismissVC {
    EventManager *eventManager = [EventManager sharedManager];
    NSError *error;
    if (![eventManager.eventStore removeEvent:self.currentEvent span:EKSpanFutureEvents error:&error]) {
        NSLog(@"error = %@", [error localizedDescription]);
    } else {
        NSLog(@"Successfully removed event");
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"calendarOrEventDataDidChange" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // # of rows will be based on how many customizations to the new event we will need
    if (section == 0) {
        return 2;
    } else if (section == 1 && self.isTextFieldTapped && !self.datePickerIndexPath) {
        return 2;
    } else if (section == 1 && self.datePickerIndexPath) {
        return 3;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            EventTextFieldTableViewCell *eventTextFieldCell = (EventTextFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EventTextFieldTableViewCell"];
            eventTextFieldCell.titleTextField.delegate = self;
            eventTextFieldCell.backgroundColor = [UIColor clearColor];
            
            // If we just recently pushed the RepeatAlertVC, do NOT re-assign the detail label from the title's text field.
            // Simply read in the event title which was saved from earlier.
            if (self.didPushRepeatAlertVC && self.eventTitle) {
                eventTextFieldCell.detailLabel.text = self.eventTitle;
                eventTextFieldCell.titleTextField.text = @"Title";
            } else if (self.textFieldHasTitle) {
                eventTextFieldCell.detailLabel.text = self.textFieldTitle;
                eventTextFieldCell.titleTextField.text = @"Title";
                self.eventTitle = eventTextFieldCell.detailLabel.text;
            } else {
                eventTextFieldCell.detailLabel.text = @"";
            }
            return eventTextFieldCell;
            
        } else if (indexPath.row == 1) {
            EventTableViewCell *eventCell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EventTableViewCell"];
            eventCell.backgroundColor = [UIColor clearColor];
            eventCell.textLabel.text = @"Category";
            eventCell.detailTextLabel.text = self.eventCalendar.title;
            eventCell.detailTextLabel.textColor = [UIColor colorWithCGColor:self.eventCalendar.CGColor];
            return eventCell;
        }
    }
    
    if (indexPath.section == 1 && self.datePickerIndexPath && self.datePickerIndexPath == indexPath) {
        DatePickerTableViewCell *datePickerCell = (DatePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DatePickerTableViewCell"];
        datePickerCell.backgroundColor = [UIColor clearColor];
        // A date picker sends the UIControlEventValueChanged event when the user finishes rotating one of the wheels to change the date or time. You can respond to this event by performing some corresponding action in your app, such as updating the time for a calendar event. You register the target-action methods for a date picker as shown below.
        [datePickerCell.datePicker addTarget:self
                                      action:@selector(changeDateAboveDatePicker:)
                            forControlEvents:UIControlEventValueChanged];
        
        if (indexPath.row == 1) {
            [datePickerCell.datePicker setDate:self.eventStartDate animated:YES];
        } else if (indexPath.row == 2) {
            [datePickerCell.datePicker setDate:self.eventEndDate animated:YES];
        }
        
        return datePickerCell;
        
    } else {
        EventTableViewCell *eventCell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"EventTableViewCell"];
        eventCell.backgroundColor = [UIColor clearColor];
        if (indexPath.section == 1) {
            
            if (indexPath.row == 0) {
                eventCell.textLabel.text = @"Starts";
                eventCell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.eventStartDate];
            } else if (indexPath.row == 1) {
                eventCell.textLabel.text = @"Ends";
                eventCell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.eventEndDate];
            }
            
        } else if (indexPath.section == 2) {
            
            if (indexPath.row == 0) {
                eventCell.textLabel.text = @"Repeat";
                if (self.eventHasRepeat) {
                    eventCell.detailTextLabel.text = self.repeatString;
                } else {
                    eventCell.detailTextLabel.text = @"Never";
                }
                
            } else if (indexPath.row == 1) {
                eventCell.textLabel.text = @"Alarm";
                if (self.eventHasAlarm) {
                    eventCell.detailTextLabel.text = self.alarmString;
                } else {
                    eventCell.detailTextLabel.text = @"None";
                }
            }
        }
        
        return eventCell;
    }
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
    
    // Need to call beginUpdates since multiple actions are being done below
    [tableView beginUpdates];
    
    // If a date picker is shown and we tap the row right above it, or any row in another section,
    // hide and delete the current date picker and its row
    if ((self.datePickerIndexPath && self.datePickerIndexPath.row - 1 == indexPath.row) ||
        (self.datePickerIndexPath && indexPath.section == 0) ||
        (self.datePickerIndexPath && indexPath.section == 2)) {
        [tableView deleteRowsAtIndexPaths:@[self.datePickerIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
        
    } else {
        // If a date picker is shown and we tap a row that isn't right above it, then hide the date picker and show another date picker under the tapped row.
        if (self.datePickerIndexPath) {
            [tableView deleteRowsAtIndexPaths:@[self.datePickerIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        // If we're in correct section, get the location of the date picker and insert that row
        if (indexPath.section == 1) {
            self.datePickerIndexPath = [self calculateDatePickerIndexPath:indexPath];
            [tableView insertRowsAtIndexPaths:@[self.datePickerIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    
    self.isTextFieldTapped = NO;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView endUpdates];
    
    if (indexPath.section == 2) {
        
        RepeatAlertViewController *repeatVC = [RepeatAlertViewController new];
        repeatVC.delegate = self;
        
        if (indexPath.row == 0) {
            repeatVC.repeatOrAlarm = @"Repeat";
            repeatVC.checkedRowForRepeat = self.repeatIndex;
        } else if (indexPath.row == 1) {
            repeatVC.repeatOrAlarm = @"Alarm";
            repeatVC.checkedRowForAlarm = self.alarmIndex;
        }
        
        [self.navigationController pushViewController:repeatVC animated:YES];
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            CategoriesViewController *categoriesVC = [[CategoriesViewController alloc] initWithCalendar:self.eventCalendar
                                                                                               delegate:self];
            [self.navigationController pushViewController:categoriesVC animated:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat rowHeight = tableView.rowHeight;
    
    // If we have a date picker shown at the corresponding index path, make sure the height is what is set as in IB.
    if (self.datePickerIndexPath && self.datePickerIndexPath == indexPath) {
        DatePickerTableViewCell *datePickerCell = (DatePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DatePickerTableViewCell"];
        rowHeight = datePickerCell.frame.size.height;
    }
    
    return rowHeight;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//  if (section == 0) return 30.0;
//  else return CGFLOAT_MIN;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//  // If we're at last section of table view, return min value
//  if (section == 2) return CGFLOAT_MIN;
//  else return 30.0;
//}

// Simple way to get a transparent section header without creating your own header views.
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
        headerView.contentView.backgroundColor = [UIColor clearColor];
        headerView.backgroundView.backgroundColor = [UIColor clearColor];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *footerView = (UITableViewHeaderFooterView *)view;
        footerView.contentView.backgroundColor = [UIColor clearColor];
        footerView.backgroundView.backgroundColor = [UIColor clearColor];
    }
}

//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//  // Create a horizontal, dark gray line and insert it as a subview of our custom headerView.
//  UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width - 87, 5.30)];
//  lineView.backgroundColor = [UIColor lightGrayColor];
//
//  return lineView;
//}


#pragma mark - CategoriesViewControllerDelegate


- (void)didSelectCalendar:(EKCalendar *)calendar {
    self.eventCalendar = calendar;
}


#pragma mark - RepeatAlertViewControllerDelegate


- (void)didPushRepeatAlertViewController:(BOOL)boolean {
    self.didPushRepeatAlertVC = boolean;
}

- (void)didSelectRepeatOption:(NSInteger)index {
    self.repeatIndex = index;
    self.repeatString = self.repeatOptions[index];
}

- (void)didSelectAlarmOption:(NSInteger)index {
    self.alarmIndex = index;
    self.alarmString = self.alarmOptions[index];
}


#pragma mark - DatePicker Methods


- (NSIndexPath *)calculateDatePickerIndexPath:(NSIndexPath *)indexPathSelected {
    // If the tapped row is under the shown date picker,
    // return the selected index path's row (since the selected row will now become the index of the date picker)
    if (self.datePickerIndexPath && self.datePickerIndexPath.row < indexPathSelected.row) {
        return [NSIndexPath indexPathForRow:indexPathSelected.row inSection:1];
        
        // If the tapped row is above the shown date picker, the date picker's index will be right below the selected row (+1)
    } else {
        return [NSIndexPath indexPathForRow:indexPathSelected.row + 1 inSection:1];
    }
}

- (void)changeDateAboveDatePicker:(UIDatePicker *)sender {
    // When the date picker changes its date value, call changeDateAboveDatePicker: to update the event cell's label
    NSIndexPath *parentIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row - 1 inSection:1];
    
    EventTableViewCell *eventCell = [self.editEventTableView cellForRowAtIndexPath:parentIndexPath];
    eventCell.detailTextLabel.text = [self.dateFormatter stringFromDate:sender.date];
    
    if (parentIndexPath.row == 0) {
        self.eventStartDate = sender.date;
    } else if (parentIndexPath.row == 1) {
        self.eventEndDate = sender.date;
    }
}


#pragma mark - Private Methods


- (void)configureViewAndEventTableView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.clipsToBounds = NO;
    
    self.editEventTableView.backgroundColor = [UIColor clearColor];
    self.editEventTableView.backgroundView.backgroundColor = [UIColor clearColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Insert a dummy footer view to limit number of cells displayed in table view
    self.editEventTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Do NOT modify the content area of the scroll view using the safe area insets
    if (@available(iOS 11.0, *)) {
        self.editEventTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

- (void)customizeTitle {
    // Customize title on nav bar
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0f];
    label.textAlignment = NSTextAlignmentCenter;
//    label.textColor = [UIColor colorWithCGColor:self.currentEvent.calendar.CGColor];
    label.textColor = [UIColor blackColor];
    //    label.text = self.eventTitle;
    label.text = @"Edit Event";
    [label sizeToFit];
    self.navigationItem.titleView = label;
}

- (void)customizeBarButtonItems {
    NSDictionary *textAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:14.0], NSForegroundColorAttributeName : [UIColor blackColor] };
    
    UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(dismissVC)];
    [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    [leftButtonItem setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    leftButtonItem.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(saveEvent:)];
    [saveButton setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
    [saveButton setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
    saveButton.tintColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = saveButton;
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)customizeDatesAndOptions {
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    self.repeatOptions = @[@"Never", @"Daily", @"Weekly", @"Monthly", @"Yearly"];
    self.alarmOptions = @[@"None", @"At time of event", @"5 minutes before", @"10 minutes before", @"30 minutes before", @"1 hour before"];
}

- (void)registerCellSubclasses {
    // Load and register our 3 cell subclasses
    UINib *nib = [UINib nibWithNibName:@"EventTableViewCell" bundle:nil];
    UINib *nib2 = [UINib nibWithNibName:@"DatePickerTableViewCell" bundle:nil];
    UINib *nib3 = [UINib nibWithNibName:@"EventTextFieldTableViewCell" bundle:nil];
    [self.editEventTableView registerNib:nib forCellReuseIdentifier:@"EventTableViewCell"];
    [self.editEventTableView registerNib:nib2 forCellReuseIdentifier:@"DatePickerTableViewCell"];
    [self.editEventTableView registerNib:nib3 forCellReuseIdentifier:@"EventTextFieldTableViewCell"];
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














