//
//  EventTextViewTableViewCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/4/19.
//  Copyright © 2019 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface EventTextViewTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

NS_ASSUME_NONNULL_END
