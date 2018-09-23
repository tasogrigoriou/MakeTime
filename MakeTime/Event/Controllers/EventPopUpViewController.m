//
//  EventPopUpViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/20/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "EventPopUpViewController.h"
#import "EditEventViewController.h"
#import "UIView+Extras.h"
#import "Chameleon.h"


@interface EventPopUpViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *popUpView;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (strong, nonatomic) EKEvent *event;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;

@end


@implementation EventPopUpViewController


#pragma mark - Initialization


- (instancetype)initWithEvent:(EKEvent *)event
                     delegate:(id<EventPopUpDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        self.event = event;
        self.delegate = delegate;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    
    return self;
}


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    [self roundCorners];
    [self setupTextView];
    [self setupTapRecognizer];
}


#pragma mark - IBActions


- (IBAction)cancelButtonPressed:(id)sender {
    [self dismissVC];
}

- (IBAction)editButtonPressed:(id)sender {
    __weak EventPopUpViewController *weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        [weakSelf.delegate editEventButtonPressedWithEvent:weakSelf.event];
    }];
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


- (void)roundCorners {
    self.popUpView.layer.cornerRadius = 40.0f;
    self.textView.layer.cornerRadius = 20.0f;
    [self.headerView setRoundedCorners:UIRectCornerTopLeft | UIRectCornerTopRight radius:10.0f];
    [self.cancelButton setRoundedCorners:UIRectCornerBottomLeft radius:10.0f];
    [self.editButton setRoundedCorners:UIRectCornerBottomRight | UIRectCornerBottomLeft radius:10.0f];
//    self.editButton.backgroundColor = [UIColor flatGreenColor];
    self.editButton.backgroundColor = [UIColor colorWithCGColor:self.event.calendar.CGColor];
}

- (void)setupTextView {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale currentLocale];
    formatter.dateFormat = @"MMM d, h:mm a";
    
    NSString *startDateTitle = [formatter stringFromDate:self.event.startDate];
    NSString *endDateTitle = [formatter stringFromDate:self.event.endDate];
    
    NSString *noEventTitle = @"No Title";
    
    if (self.event.title.length != 0) {
        self.textView.text = [NSString stringWithFormat:@"Title: %@ \nCategory: %@ \nStart: %@ \nEnd: %@", self.event.title, self.event.calendar.title, startDateTitle, endDateTitle];
    } else {
        self.textView.text = [NSString stringWithFormat:@"Title: %@ \nCategory: %@ \nStart: %@ \nEnd: %@", noEventTitle, self.event.calendar.title, startDateTitle, endDateTitle];
    }
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
