//
//  AlbumRepository.m
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import "AlbumRepository.h"

#define kAlbumEncodingKey        @"kAlbumEncodingKey"
#define kAlbumEncodingFilename   @"kAlbumEncodingFilename.rec"
#define kAlbumEncodingFoldername @"kAlbumEncodingFoldername"

@interface AlbumRepository (){
    dispatch_queue_t _taskQueue;
}

@end

@implementation AlbumRepository

- (id)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    _taskQueue = dispatch_queue_create("AlbumRepository", DISPATCH_QUEUE_SERIAL);
    _albums = [NSMutableArray new];
    
    return self;
}

- (void)loadAlbums:(void(^)(NSError * error))complete{
    void (^block)() = ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self albumsFilenPath]]) {
            NSData *data = [NSData dataWithContentsOfFile:[self albumsFilenPath]];
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            NSArray *albums = [unarchiver decodeObjectForKey:kAlbumEncodingKey];
            [unarchiver finishDecoding];
            if (albums.count) {
                [_albums setArray:albums];
            }
            complete(NULL);
        }
        else{
            complete([NSError errorWithDomain:@"REC" code:0 userInfo:nil]);
        }
    };
    dispatch_async(_taskQueue, ^{
        block();
    });
}

- (void)saveAlbums:(void(^)(NSError * error))complete{
    void (^block)() = ^{
        if (_albums.count) {
            NSMutableData *data = [[NSMutableData alloc] init];
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            [archiver encodeObject:_albums forKey:kAlbumEncodingKey];
            [archiver finishEncoding];
            NSError *error = nil;
            [data writeToFile:[self albumsFilenPath] options:NSDataWritingAtomic error:&error];
            //TODO: Check Error
            complete != nil ? complete(error) : 0;
        }
        else{
            complete != nil ? complete(NULL) : 0;
        }
    };
    dispatch_async(_taskQueue, ^{
        block();
    });
}

- (void)addAlbum:(Album*)album completed:(void(^)(NSError * error))complete{
    void (^block)() = ^{
        if (![_albums containsObject:album]) {
            [_albums addObject:album];
        }
        complete != nil ? complete(NULL) : 0;
    };
    dispatch_async(_taskQueue, ^{
        block();
    });
}

- (void)removeAlbum:(Album*)album completed:(void(^)(NSError * error))complete{
    void (^block)() = ^{
        if ([_albums containsObject:album]) {
            [_albums removeObject:album];
        }
        complete != nil ? complete(NULL) : 0;
    };
    dispatch_async(_taskQueue, ^{
        block();
    });
}

- (NSString*)albumsFilenPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    NSString *folder = [applicationSupportDirectory stringByAppendingPathComponent:kAlbumEncodingFoldername];
    if ([[NSFileManager defaultManager] fileExistsAtPath:folder] == NO) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
        //TODO: Need check Error to make sure folder was create
    }
    NSString *filePath = [folder stringByAppendingPathComponent:kAlbumEncodingFilename];
    
    return filePath;
}

- (NSString*)albumsFolderPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    NSString *folder = [applicationSupportDirectory stringByAppendingPathComponent:kAlbumEncodingFoldername];
    if ([[NSFileManager defaultManager] fileExistsAtPath:folder] == NO) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
        //TODO: Need check Error to make sure folder was create
    }
    
    return folder;
}

@end
