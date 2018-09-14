//
//  Task+CoreDataProperties.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 9/13/18.
//  Copyright © 2018 Grigoriou. All rights reserved.
//
//

#import "Task+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Task (CoreDataProperties)

+ (NSFetchRequest<Task *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) BOOL isComplete;
@property (nullable, nonatomic, copy) NSDate *date;

@end

NS_ASSUME_NONNULL_END
