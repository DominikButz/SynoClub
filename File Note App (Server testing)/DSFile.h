//
//  DSFile.h
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import <Foundation/Foundation.h>

typedef void(^ThumbnailCompletionBlock)();

@interface DSFile : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSString *contents;
@property (strong, nonatomic) NSDate *modified;
@property (strong, nonatomic) NSString *mimeType;
@property (nonatomic, strong) UIImage *thumbNail;


- (id)initWithJSONData:(NSDictionary*)data;

-(NSString *)fileNameShowExtension:(BOOL)showExtension;

@end
