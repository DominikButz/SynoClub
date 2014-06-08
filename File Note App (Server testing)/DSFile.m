//
//  DSFile.m
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import "DSFile.h"

@implementation DSFile

- (id)initWithJSONData:(NSDictionary*)data
{
    self = [super init];
    if (self) {
        self.path = data[@"path"];
        self.name= data[@"name"];

        NSDate *date = [self convertUnixTimeStamptoNSDate:data[@"additional"][@"time"][@"mtime"]];
       
        if (date) {
            self.modified = date;
        }
        self.mimeType = data[@"mime_type"];
    }
    return self;
}

// file station returns date as unix time stamp (seconds since 0:00 1/1/1970, need to convert to nsdate!
-(NSDate *)convertUnixTimeStamptoNSDate:(NSString*)timeStampString{
    
    long timeStamp = [timeStampString integerValue];
    NSTimeInterval interval = timeStamp;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    return date;
}

-(NSString *)fileNameShowExtension:(BOOL)showExtension
{
    NSString *path = self.path;
    NSString *filePath = [[path componentsSeparatedByString:@"/"] lastObject];
    if (!showExtension) {
        filePath = [[filePath componentsSeparatedByString:@"."] firstObject];
    }
    return filePath;
}


// sort by level, then acheivement points
- (NSComparisonResult)compare:(DSFile *)other
{
    NSComparisonResult order;
    
    // first compare modified
    order = [other.modified compare:self.modified];
    
    // if same modified alpha by path
    if (order == NSOrderedSame) {
        order = [other.path compare:self.path];
    }
    return order;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"File from %@", self.path];
}


@end
