//
//  PersistenceService.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/13/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PersistenceService : NSObject

@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (readonly, strong) NSManagedObjectContext *context;

+ (id)sharedService;

- (void)saveContext:(void (^)(BOOL success))completion;

@end
