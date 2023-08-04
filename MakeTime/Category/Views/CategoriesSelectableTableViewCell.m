//
//  CategoriesSelectableTableViewCell.m
//  MakeTime
//
//  Created by Anastasios Grigoriou on 8/3/23.
//  Copyright © 2023 Grigoriou. All rights reserved.
//

#import "CategoriesSelectableTableViewCell.h"
#import "UIColor+RBExtras.h"

@interface CategoriesSelectableTableViewCell ()

@end

@implementation CategoriesSelectableTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.delegate = nil;
}

// Override initWithFrame: to load our xib file into an array and assign the object (the xib file) to self.
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        // Load our CategoriesSelectableTableViewCell xib file into an array.
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"CategoriesSelectableTableViewCell" owner:self options:nil];
        
        if ([arrayOfViews count] < 1) {
            return nil;
        }
        if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UITableViewCell class]]) {
            return nil;
        }
        
        // Assign the nib to our instance of CategoriesSelectableTableViewCell
        self = [arrayOfViews objectAtIndex:0];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
}

- (IBAction)didTapCalendarCheckboxButton:(UIButton *)sender {
    [self.delegate didTapCalendarCheckboxButtonForCell:self];
}

@end
