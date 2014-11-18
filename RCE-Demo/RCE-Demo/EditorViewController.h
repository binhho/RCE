//
//  EditorViewController.h
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Album;
@class Record;

@interface EditorViewController : UIViewController

@property (nonatomic) Album *album;

- (void)startEditAtRecord:(Record*)record;

@end
