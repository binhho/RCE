//
//  Record.h
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, Type_Record) {
    Type_RecordText = 0,
    Type_RecordPhoto
};

@interface Record : NSObject <NSCoding>

@property (nonatomic, copy  ) NSString    * id;
@property (nonatomic, assign) Type_Record type;
@property (nonatomic, copy  ) NSString    * textContent;
@property (nonatomic) float imgWidth;
@property (nonatomic) float imgHeight;

- (NSString*)imgFilename;

@end
