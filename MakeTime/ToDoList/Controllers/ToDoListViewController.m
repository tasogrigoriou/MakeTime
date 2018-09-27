//
//  ToDoListViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/13/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "ToDoListViewController.h"
#import "ToDoTableViewCell.h"
#import "PersistenceService.h"
#import "Task+CoreDataClass.h"

@interface ToDoListViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (strong, nonatomic) NSArray<Task *> *fetchedTasks;

@property (strong, nonatomic) NSMutableArray<Task *> *currentTasks;
@property (strong, nonatomic) NSMutableArray<Task *> *completedTasks;

@property (nonatomic) BOOL keyboardIsShowing;

@end


@implementation ToDoListViewController


#pragma mark - View Lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableView];
    [self setupNavBarTitle];
    [self addTapGestureRecognizer];
    [self loadData];
}


#pragma mark - Core Data Methods


- (void)fetchTasks:(void (^)(BOOL success))completion {
    NSError *error;
    self.fetchedTasks = [[[PersistenceService sharedService] context] executeFetchRequest:[Task fetchRequest] error:&error];
    if (error != nil) {
        NSLog(@"Could not fetch - %@", [error localizedDescription]);
        completion(NO);
    } else {
        completion(YES);
    }
}

- (void)saveNewTask:(NSString *)name completion:(void (^)(BOOL success))completion {
    Task *newTask = [[Task alloc] initWithContext:[[PersistenceService sharedService] context]];
    newTask.name = name;
    newTask.date = [NSDate date];
    newTask.isComplete = NO;
    
    [self.currentTasks addObject:newTask];

    [[PersistenceService sharedService] saveContext:completion];
}

- (void)setTaskToCompleted:(Task *)task {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        task.isComplete = YES;
        [self.currentTasks removeObject:task];
        [self.completedTasks insertObject:task atIndex:0];
        
        [[PersistenceService sharedService] saveContext:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}


#pragma mark - IBActions


- (IBAction)addButtonPressed:(UIButton *)sender {
    if (self.textField.text.length != 0) {
        __weak ToDoListViewController *weakSelf = self;
        [self saveNewTask:self.textField.text completion:^(BOOL success) {
            if (success) {
                [weakSelf.tableView reloadData];
            }
        }];
    }
    [self.textField resignFirstResponder];
    self.textField.text = @"";
}


#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.currentTasks count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ToDoTableViewCell *cell = (ToDoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ToDoTableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = self.currentTasks[indexPath.row].name;
    return cell;
}


#pragma mark - UITableViewDelegate


- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.keyboardIsShowing) {
        self.keyboardIsShowing = NO;
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setTaskToCompleted:self.currentTasks[indexPath.row]];
}


#pragma mark - UITextFieldDelegate


// The text field calls this method whenever the user taps the return button.
// Use this method to implement any custom behavior when return is tapped (MUST make sure delegate is set in XIB).
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length != 0) {
        __weak ToDoListViewController *weakSelf = self;
        [self saveNewTask:textField.text completion:^(BOOL success) {
            if (success) {
                [weakSelf.tableView reloadData];
            }
        }];
    }
    
    [textField resignFirstResponder];
    textField.text = @"";
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.textField = textField;
    self.keyboardIsShowing = YES;
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason {
    
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}


#pragma mark - Private Methods


- (void)loadData {
    __weak ToDoListViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self fetchTasks:^(BOOL success) {
            if (success) {
                [weakSelf setupCurrentAndCompletedTasks];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                });
            }
        }];
    });
}

- (void)setupCurrentAndCompletedTasks {
    for (Task *task in self.fetchedTasks) {
        if (task.isComplete) {
            [self.completedTasks addObject:task];
        } else {
            [self.currentTasks addObject:task];
        }
    }
}

- (void)setupTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"ToDoTableViewCell" bundle:nil] forCellReuseIdentifier:@"ToDoTableViewCell"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)setupNavBarTitle {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0f];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor blackColor];
    label.text = @"To Do List";
    [label sizeToFit];
    self.navigationItem.titleView = label;
}

- (void)addTapGestureRecognizer {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self.view action:@selector(endEditing:)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGestureRecognizer];
}


#pragma mark - Custom Accessors


- (NSMutableArray<Task *> *)currentTasks {
    if (!_currentTasks) {
        _currentTasks = [NSMutableArray array];
    }
    return _currentTasks;
}


@end
