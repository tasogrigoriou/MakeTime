//
//  CategoriesTableViewCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 6/15/17.
//  Copyright © 2017 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoriesTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *categoriesColorView;
@property (weak, nonatomic) IBOutlet UILabel *categoriesLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImage;

@end
