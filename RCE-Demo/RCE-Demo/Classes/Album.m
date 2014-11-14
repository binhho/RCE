//
//  Album.m
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import "Album.h"
#import "NSString+REC.h"
#import "AlbumRepository.h"

#define kEncodingAlbumIdKey       @"kEncodingAlbumIdKey"
#define kEncodingAlbumNameKey     @"kEncodingAlbumNameKey"
#define kEncodingAlbumExcerptKey  @"kEncodingAlbumExcerptKey"
#define kEncodingAlbumCreateAtKey @"kEncodingAlbumCreateAtKey"

#define kEncodingRecordFileName @"kEncodingRecordFileName.recs"
#define kEncodingRecordFolder @"kEncodingRecordFolder"
#define kEncodingRecordKey @"records"

@interface Album ()

@property (nonatomic) dispatch_queue_t taskQueue;

@end

@implementation Album

@synthesize records = _records;
@synthesize taskQueue = _taskQueue;

- (id)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _id = [NSString uuidString];
    
    return self;
}

#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (!self) {
        return nil;
    }
    //init existing value
    _id       = [aDecoder decodeObjectForKey:kEncodingAlbumIdKey];
    _name     = [aDecoder decodeObjectForKey:kEncodingAlbumNameKey];
    _excerpt  = [aDecoder decodeObjectForKey:kEncodingAlbumExcerptKey];
    _createAt = [aDecoder decodeObjectForKey:kEncodingAlbumCreateAtKey];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.id forKey:kEncodingAlbumIdKey];
    [aCoder encodeObject:self.name forKey:kEncodingAlbumNameKey];
    [aCoder encodeObject:self.excerpt forKey:kEncodingAlbumExcerptKey];
    [aCoder encodeObject:self.createAt forKey:kEncodingAlbumCreateAtKey];
}

#pragma mark - 

- (dispatch_queue_t)taskQueue{
    if (_taskQueue == nil) {
        _taskQueue = dispatch_queue_create([_id cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
    }
    
    return _taskQueue;
}

- (NSMutableArray*)records{
    if (!_records) {
        _records = [NSMutableArray new];
    }
    
    return _records;
}

- (void)loadRecords:(void(^)(NSError * error))complete{
    void (^block)() = ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self recordsFilePath]]) {
            NSData *data = [NSData dataWithContentsOfFile:[self recordsFilePath]];
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            NSArray *albums = [unarchiver decodeObjectForKey:kEncodingRecordKey];
            [unarchiver finishDecoding];
            if (albums.count) {
                [self.records setArray:albums];
            }
            complete(NULL);
        }
        else{
            complete([NSError errorWithDomain:@"REC" code:0 userInfo:nil]);
        }
    };
    dispatch_async(self.taskQueue, ^{
        block();
    });
}

- (void)saveRecords:(void(^)(NSError * error))complete{
    void (^block)() = ^{
        if (self.records.count) {
            NSMutableData *data = [[NSMutableData alloc] init];
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            [archiver encodeObject:self.records forKey:kEncodingRecordKey];
            [archiver finishEncoding];
            NSError *error = nil;
            [data writeToFile:[self recordsFilePath] options:NSDataWritingAtomic error:&error];
            //TODO: Check Error
            complete != nil ? complete(error) : 0;
        }
        else{
            complete != nil ? complete(NULL) : 0;
        }
    };
    dispatch_async(self.taskQueue, ^{
        block();
    });
}

- (void)addRecord:(Record*)record completed:(void(^)(NSError * error))complete{
    void (^block)() = ^{
        if (![self.records containsObject:record]) {
            [self.records addObject:record];
        }
        complete != nil ? complete(NULL) : 0;
    };
    dispatch_async(self.taskQueue, ^{
        block();
    });
}

- (void)removeRecord:(Record*)record completed:(void(^)(NSError * error))complete{
    void (^block)() = ^{
        if ([self.records containsObject:record]) {
            [self.records removeObject:self.records];
        }
        complete != nil ? complete(NULL) : 0;
    };
    dispatch_async(self.taskQueue, ^{
        block();
    });
}

- (NSString*)recordsFilePath{
    AlbumRepository *repo = [[AlbumRepository alloc] init];
    NSString *folder      = [[repo albumsFolderPath] stringByAppendingPathComponent:_id];
    if ([[NSFileManager defaultManager] fileExistsAtPath:folder] == NO) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
        //TODO: Need check Error to make sure folder was create
    }
    NSString *filePath = [folder stringByAppendingPathComponent:kEncodingRecordFileName];
    
    return filePath;
}

@end
