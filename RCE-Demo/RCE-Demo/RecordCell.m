//
//  RecordCell.m
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import "RecordCell.h"
#import "Record.h"
#import "EditorViewController.h"

@interface RecordCell () <UITextViewDelegate>
@end

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
        //Init Content Text View
        _contentTextView                 = [[UITextView alloc] initWithFrame:CGRectZero];
        _contentTextView.textColor       = [UIColor blackColor];
        _contentTextView.backgroundColor = [UIColor grayColor];
        _contentTextView.textAlignment   = NSTextAlignmentCenter;
        _contentTextView.font            = [UIFont systemFontOfSize:13.0f];
        _contentTextView.tag             = kRecordCellContentTextViewTag;
        _contentTextView.editable        = YES;
        _contentTextView.delegate        = self;
        _contentTextView.scrollEnabled   = NO;
        [self.contentView addSubview:_contentTextView];
        
        //Init Photo Image View
        _photoImageView                 = [[UIImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.backgroundColor = [UIColor clearColor];
        _photoImageView.tag             = kRecordCellPhotoImageViewTag;
        [self.contentView addSubview:_photoImageView];
        
        self.contentView.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    if (_editorVC && _record) {
        [_editorVC startEditAtRecord:_record];
    }
    
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if([text isEqualToString:@"\n"]){
        _record.textContent = [textView.text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        [textView resignFirstResponder];
    }
        
    return YES;
}

@end
