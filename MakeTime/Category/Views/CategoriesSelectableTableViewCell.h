//
//  CategoriesSelectableTableViewCell.h
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/3/23.
//  Copyright © 2023 Grigoriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CategoriesSelectableTableViewCell;

NS_ASSUME_NONNULL_BEGIN

@protocol CategoriesSelectableTableViewCellDelegate <NSObject>

- (void)didTapCalendarCheckboxButtonForCell:(CategoriesSelectableTableViewCell *)cell;

@end

@interface CategoriesSelectableTableViewCell : UITableViewCell

@property (weak, nonatomic) id<CategoriesSelectableTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *checkboxImageView;
@property (weak, nonatomic) IBOutlet UIButton *calendarCheckboxButton;
@property (weak, nonatomic) IBOutlet UILabel *categoriesLabel;

- (IBAction)didTapCalendarCheckboxButton:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
