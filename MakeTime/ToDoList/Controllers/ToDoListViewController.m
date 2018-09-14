//
//  ToDoListViewController.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/13/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "ToDoListViewController.h"
#import "AppDelegate.h"
#import "ToDoTableViewCell.h"

@interface ToDoListViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (strong, nonatomic) AppDelegate *appDelegate;

@property (strong, nonatomic) NSArray<NSManagedObject *> *tasks;

@end


@implementation ToDoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableView];
    [self loadData];
}

- (void)loadData {
    __weak ToDoListViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self fetchTasks:^(BOOL success) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                });
            }
        }];
    });
}

#pragma mark - Core Data Methods


- (void)fetchTasks:(void (^)(BOOL success))completion {
    NSManagedObjectContext *context = self.appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest<NSManagedObject *> *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    
    NSError *error;
    self.tasks = [context executeFetchRequest:fetchRequest error:&error];
    if (error != nil) {
        NSLog(@"Could not fetch - %@", [error localizedDescription]);
        completion(NO);
    } else {
        completion(YES);
    }
}

- (void)saveTask:(NSString *)name completion:(void (^)(BOOL success))completion {
    NSManagedObjectContext *context = self.appDelegate.persistentContainer.viewContext;
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:context];
    NSManagedObject *task = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    
    [task setValue:name forKeyPath:@"name"];
    
    NSError *error;
    [context save:&error];
    if (error != nil) {
        NSLog(@"Could not save task - %@", [error localizedDescription]);
        completion(NO);
    } else {
        completion(YES);
    }
}

- (void)saveTaskAndRefreshTableView:(NSString *)task {
    __weak ToDoListViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self saveTask:task completion:^(BOOL success) {
            if (success) {
                [weakSelf fetchTasks:^(BOOL success) {
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.tableView reloadData];
                        });
                    }
                }];
            }
        }];
    });
}


#pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tasks count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ToDoTableViewCell *cell = (ToDoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ToDoTableViewCell" forIndexPath:indexPath];
    
    NSString *taskName = [self.tasks[indexPath.row] valueForKeyPath:@"name"];
    cell.textLabel.text = taskName;
    
    return cell;
}


#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


#pragma mark - UITextFieldDelegate


// The text field calls this method whenever the user taps the return button.
// Use this method to implement any custom behavior when return is tapped (MUST make sure delegate is set in XIB).
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length != 0) {
        [self saveTaskAndRefreshTableView:textField.text];
    }
    
    [textField resignFirstResponder];
    textField.text = @"";
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField reason:(UITextFieldDidEndEditingReason)reason {
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.textField = textField;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}


#pragma mark - Private Methods


- (void)setupTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"ToDoTableViewCell" bundle:nil] forCellReuseIdentifier:@"ToDoTableViewCell"];
}


#pragma mark - Custom Getters


- (AppDelegate *)appDelegate {
    if (!_appDelegate) {
        _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return _appDelegate;
}

@end
