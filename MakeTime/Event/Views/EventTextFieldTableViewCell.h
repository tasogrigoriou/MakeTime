//
//  EventTextFieldTableViewCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 7/24/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventTextFieldTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end
