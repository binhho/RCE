//
//  RecordCell.m
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import "RecordCell.h"

@implementation RecordCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _contentTextView                 = [[UITextView alloc] initWithFrame:CGRectZero];
        _contentTextView.textColor       = [UIColor blackColor];
        _contentTextView.backgroundColor = [UIColor grayColor];
        _contentTextView.textAlignment   = NSTextAlignmentCenter;
        _contentTextView.font            = [UIFont systemFontOfSize:13.0f];
        _contentTextView.tag             = kRecordCellContentTextViewTag;
        _contentTextView.editable = YES;
        _contentTextView.scrollEnabled = NO;
        [self.contentView addSubview:_contentTextView];
    }
    
    return self;
}

@end
