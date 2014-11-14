//
//  RecordCell.h
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kRecordCellContentTextViewTag 100

@interface RecordCell : UITableViewCell

@property(nonatomic, strong) UITextView *contentTextView;

@end
