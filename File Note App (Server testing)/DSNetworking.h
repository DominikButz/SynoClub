//
//  DSNetworking.h
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import <Foundation/Foundation.h>


extern NSString *const appFolder;
extern NSString *const photoFolder;

//@interface NSMutableURLRequest(Private)
//+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
//@end

@interface DSNetworking : NSObject

+(BOOL)isFileStationWorkingForHost:(NSString *)hostName andHttpsOn:(BOOL)httpsSelected;

+(NSURL *)loginURLwithAccount: (NSString*)account PW:(NSString *)pw host:(NSString *)hostName andSession:(NSURLSession *)session andHttpsOn:(BOOL)httpsSelected;

+(NSURL *) listSharedFolderURLWithHost: (NSString *)host HttpsOn: (BOOL)httpsSelected andSessionID:(NSString *)sid;

+(NSURL *)listFilesInAppRootFolderWithSharedFolderName:(NSString *)sharedFolder Host:(NSString *)host andHttpsOn:(BOOL)httpsSelected andSid:(NSString *)sid;

+(NSURL *)listPhotosInPhotoFolderWithSharedFolderName:(NSString *)sharedFolder Host: (NSString *)host andHttpsOn:(BOOL)httpsSelected andSid:(NSString *)sid;

+(NSURL *) createAppFoldersWithHost:(NSString *)host  sessionID:(NSString *)sid SharedFolder:(NSString *)sharedFolderName FolderPath:(NSString *)folderPath andHttpsOn:(BOOL)httpsSelected;

+(NSURL *) downloadURLFileContentWithHost:(NSString *)host sessionID:(NSString *)sid andPath:(NSString *)path andHttpsOn:(BOOL)httpsSelected;
+(NSURL *)downloadURLForPhotoThumbnailWithHost: (NSString *)host sessionID: (NSString *)sid andPath: (NSString *)path andHttpsOn:(BOOL)httpsSelected;

+(NSURL *)uploadURLwithHost: (NSString *)host andHttpsOn:(BOOL)httpsSelected;
+(NSURLRequest *)urlRequestForUploadWith:(NSURL *) url fileName:(NSString *)fileName fileContent:(NSData *)fileContent AndSessionID:(NSString *)sid andFolderPath:(NSString *)folderPath;

+(NSURL *) deleteFileURLwithHost:(NSString *)host sessionID:(NSString *)sid andPath:(NSString *)path andHttpsOn:(BOOL)httpsSelected;

+(BOOL)logoutWithHost: (NSString *)hostName Session:(NSURLSession *)session andSessionID:(NSString *)sid andHttpsOn:(BOOL)httpsSelected;


+(id)deserializeJSONobject:(NSData *)jsonData;

@end
