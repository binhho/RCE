//
//  AlbumRepository.h
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Album;

@interface AlbumRepository : NSObject

@property (nonatomic, readonly) NSMutableArray *albums;

- (void)loadAlbums:(void(^)(NSError * error))complete;
- (void)saveAlbums:(void(^)(NSError * error))complete;
- (void)addAlbum:(Album*)record completed:(void(^)(NSError * error))complete;
- (void)removeAlbum:(Album*)record completed:(void(^)(NSError * error))complete;
- (NSString*)albumsFolderPath;

@end
