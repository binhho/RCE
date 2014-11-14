//
//  Record.m
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import "Record.h"
#import "NSString+REC.h"

#define kEncodingRecordIdKey          @"kEncodingRecordIdKey"
#define kEncodingRecordTypeKey        @"kEncodingRecordTypeKey"
#define kEncodingRecordTextContentKey @"kEncodingRecordTextContentKey"

@implementation Record

- (id)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _id = [NSString uuidString];
    
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _id = [aDecoder decodeObjectForKey:kEncodingRecordIdKey];
    _type = [aDecoder decodeIntegerForKey:kEncodingRecordTypeKey];
    _textContent = [aDecoder decodeObjectForKey:kEncodingRecordTextContentKey];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_id forKey:kEncodingRecordIdKey];
    [aCoder encodeInteger:_type forKey:kEncodingRecordTypeKey];
    [aCoder encodeObject:_textContent forKey:kEncodingRecordTextContentKey];
}

@end
