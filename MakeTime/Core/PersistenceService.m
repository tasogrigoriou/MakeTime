//
//  PersistenceService.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/13/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import "PersistenceService.h"

@implementation PersistenceService


#pragma mark - Initialization


+ (id)sharedService {
    static PersistenceService *sharedMyService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyService = [[self alloc] init];
    });
    return sharedMyService;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}


#pragma mark - Core Data stack


@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"MakeTime"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                }
            }];
        }
    }
    
    return _persistentContainer;
}

@synthesize context = _context;

- (NSManagedObjectContext *)context {
    return self.persistentContainer.viewContext;
}


#pragma mark - Core Data Saving support


- (void)saveContext:(void (^)(BOOL success))completion {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    BOOL isSuccess = NO;
    if ([context hasChanges] && ![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
    } else {
        isSuccess = YES;
    }
    
    if (completion != nil) {
        completion(isSuccess);
    }
}

@end
