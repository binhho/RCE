//
//  Album.h
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Record;

@interface Album : NSObject <NSCoding>

@property (nonatomic, copy) NSString * id;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * excerpt;
@property (nonatomic, strong) NSDate * createAt;

@property (nonatomic, readonly) NSMutableArray * records;

- (void)loadRecords:(void(^)(NSError * error))complete;
- (void)saveRecords:(void(^)(NSError * error))complete;
- (void)addRecord:(Record*)record completed:(void(^)(NSError * error))complete;
- (void)removeRecord:(Record*)record completed:(void(^)(NSError * error))complete;
- (void)addPhotoRecord:(Record*)record withData:(NSData*)imgData completed:(void(^)(NSError * error))completedBlock;
- (void)getImageDataForRecord:(Record*)record completde:(void(^)(NSData *data))completedBlock;
- (void)reorderBetweenIndex:(NSInteger)fromIndex andIndex:(NSInteger)toIndex completed:(void(^)(NSError * error))complete;

@end
