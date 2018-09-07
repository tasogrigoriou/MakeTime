//
//  EventPopUpViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/20/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "EventPopUpViewController.h"
#import "EditEventViewController.h"

@interface EventPopUpViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *popUpView;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) EKEvent *event;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@end


@implementation EventPopUpViewController


#pragma mark - Initialization


- (instancetype)initWithEvent:(EKEvent *)event
                     delegate:(id<EventPopUpDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.event = event;
        self.delegate = delegate;
    }
    
    return self;
}


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTextView];
    [self setupTapRecognizer];
}


#pragma mark - IBActions


- (IBAction)cancelButtonPressed:(id)sender {
    [self dismissVC];
}

- (IBAction)editButtonPressed:(id)sender {
    EditEventViewController *editEventVC = [[EditEventViewController alloc] initWithEvent:self.event];
    [self presentViewController:editEventVC animated:YES completion:nil];
//    [self dismissViewControllerAnimated:NO completion:nil];
}


#pragma mark - UIGestureRecognizerDelegate


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        CGPoint location = [gestureRecognizer locationInView:self.view];
        return !CGRectContainsPoint(self.popUpView.frame, location);
    }
    return NO;
}


#pragma mark - Private Methods


- (void)setupTextView {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale currentLocale];
    formatter.dateFormat = @"MMM d, h:mm a";
    
    NSString *startDateTitle = [formatter stringFromDate:self.event.startDate];
    NSString *endDateTitle = [formatter stringFromDate:self.event.endDate];
    
    self.textView.text = [NSString stringWithFormat:@"Calendar: %@ \nEvent: %@ \nStart: %@ \nEnd: %@", self.event.calendar.title, self.event.title, startDateTitle, endDateTitle];
}

- (void)setupTapRecognizer {
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissVC)];
    self.tapRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.tapRecognizer];
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate didDismissViewController];
}


@end
