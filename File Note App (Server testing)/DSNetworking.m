//
//  DSNetworking.m
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import "DSNetworking.h"

NSString *const appFolder = @"SynoClub";
NSString *const photoFolder = @"Photos";

@implementation DSNetworking


+(BOOL)isFileStationWorkingForHost:(NSString *)hostName andHttpsOn:(BOOL)httpsSelected {
    
    NSString *urlAsString;
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/query.cgi?api=SYNO.API.Info&version=1&method=query&query=SYNO.API.Auth,SYNO.FileStation.List", hostName];
    }
    
    else{
    urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/query.cgi?api=SYNO.API.Info&version=1&method=query&query=SYNO.API.Auth,SYNO.FileStation.List", hostName];
    }
    
    
    NSURL *url = [NSURL URLWithString:urlAsString];
    //[NSMutableURLRequest setAllowsAnyHTTPSCertificate:YES forHost:hostName];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:20.0f];
    
    [urlRequest setHTTPMethod:@"GET"];
    
    NSError *connectionError;
    NSURLResponse *response;
    
    //if status code is 200, all is OK.
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&connectionError ];
   
    if (response !=nil) {
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        
        if (httpResp.statusCode == 200) {
            
            if (data!=nil) {
                
                NSString *info = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 NSLog(@"Info from File station: %@", info);
                if ([info rangeOfString:@"true"].location!=NSNotFound) {
                    return YES;
                }
            }
        }
    }
    return NO;

}


+(NSURL *)loginURLwithAccount: (NSString*)account PW:(NSString *)pw host:(NSString *)hostName andSession:(NSURLSession *)session andHttpsOn:(BOOL)httpsSelected {
    
    NSString *urlAsString;
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat: @"https://%@:5001/webapi/auth.cgi?api=SYNO.API.Auth&version=3&method=login&account=%@&passwd=%@&session=FileStation&format=sid", hostName, account, pw];
    }
    else {
        
         urlAsString = [NSString stringWithFormat: @"http://%@:5000/webapi/auth.cgi?api=SYNO.API.Auth&version=3&method=login&account=%@&passwd=%@&session=FileStation&format=sid", hostName, account, pw];
    }
   
    
    NSString *escapedUrlAsString = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //NSLog(@"URL: %@", escapedUrlAsString);
    
    NSURL *url = [NSURL URLWithString:escapedUrlAsString];
    
    return url;
    
    
}





+(BOOL)logoutWithHost: (NSString *)hostName Session:(NSURLSession *)session andSessionID:(NSString *)sid andHttpsOn:(BOOL)httpsSelected{
    
    NSString *urlAsString;
    
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat: @"https://%@:5001/webapi/auth.cgi?api=SYNO.API.Auth&version=1&method=logout&session=FileStation&_sid=%@",hostName, sid];
        NSLog(@"Logout urlasString: %@", urlAsString);
    }
    else {
        
        urlAsString = [NSString stringWithFormat: @"http://%@:5000/webapi/auth.cgi?api=SYNO.API.Auth&version=1&method=logout&session=FileStation&_sid=%@",hostName, sid];
        NSLog(@"Logout urlasString: %@", urlAsString);
    }
    

    NSString *escapedString = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:escapedString];
    
    NSLog(@"Logout url as escaped string: %@", escapedString);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setTimeoutInterval:20.0f];
    [urlRequest setHTTPMethod:@"GET"];
    
    __block BOOL success;
    
    [[session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
       
        
        //if (response) {
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            NSLog(@"Status code: %li", (long)httpResp.statusCode);
            
            
            //if (data) {
                
                NSDictionary *info = [DSNetworking deserializeJSONobject:data];
                
                NSLog(@"Logout-info: %@", info);
                
                success = (BOOL)info[@"success"];
                
           // }
            
        //}
    
        
    }]resume ];
    
    
    
    return success;
    
}


+(NSURL *) listSharedFolderURLWithHost: (NSString *)host HttpsOn: (BOOL)httpsSelected andSessionID:(NSString *)sid {
    
    
    NSString *urlAsString;
    
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/FileStation/file_share.cgi?api=SYNO.FileStation.List&version=1&method=list_share&_sid=%@", host, sid ];
    }
    
    else {
        urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/FileStation/file_share.cgi?api=SYNO.FileStation.List&version=1&method=list_share&_sid=%@", host, sid ];
    }
    
    
    NSString *escapedUrlAsString = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [NSURL URLWithString:escapedUrlAsString];
}


//returns the url for the folder content search datatask used to find the note files 
+(NSURL *)listFilesInAppRootFolderWithSharedFolderName: (NSString *)sharedFolder Host:(NSString *)host andHttpsOn:(BOOL)httpsSelected andSid:(NSString *)sid {
    
    NSString *urlAsString;
    
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/FileStation/file_share.cgi?api=SYNO.FileStation.List&version=1&method=list&folder_path=/%@/%@&filetype=all&_sid=%@&additional=time", host, sharedFolder, appFolder, sid];
    }
    
    else {
    urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/FileStation/file_share.cgi?api=SYNO.FileStation.List&version=1&method=list&folder_path=/%@/%@&filetype=all&_sid=%@&additional=time", host, sharedFolder, appFolder, sid];
    }
    
    
    NSString *escapedUrlAsString = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [NSURL URLWithString:escapedUrlAsString];
    
    
}

+(NSURL *)listPhotosInPhotoFolderWithSharedFolderName:(NSString *)sharedFolder Host: (NSString *)host andHttpsOn:(BOOL)httpsSelected andSid:(NSString *)sid {
    
    NSString *urlAsString;
    
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/FileStation/file_share.cgi?api=SYNO.FileStation.List&version=1&method=list&folder_path=/%@/%@/%@&filetype=all&_sid=%@&additional=time", host, sharedFolder, appFolder, photoFolder, sid];
    }
    
    else {
        urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/FileStation/file_share.cgi?api=SYNO.FileStation.List&version=1&method=list&folder_path=/%@/%@/%@&filetype=all&_sid=%@&additional=time", host, sharedFolder, appFolder, photoFolder, sid];
    }
    
    
    NSString *escapedUrlAsString = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [NSURL URLWithString:escapedUrlAsString];
    
    
}

#pragma mark - create app root folder and Photos folder

+(NSURL *) createAppFoldersWithHost:(NSString *)host  sessionID:(NSString *)sid SharedFolder:(NSString *)sharedFolderName FolderPath:(NSString *)folderPath andHttpsOn:(BOOL)httpsSelected {
    
    
    
    NSString *urlAsString;
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/FileStation/file_crtfdr.cgi?api=SYNO.FileStation.CreateFolder&version=1&method=create&folder_path=/%@&name=%@&force_parent=true&_sid=%@", host, sharedFolderName, folderPath, sid];
        
        
    }
    else {
        
        urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/FileStation/file_crtfdr.cgi?api=SYNO.FileStation.CreateFolder&version=1&method=create&folder_path=/%@&name=%@&force_parent=true&_sid=%@", host, sharedFolderName, folderPath, sid];
    }
    
    // NSLog(@"Download URL as string: %@", urlAsString);
    
    
    return [NSURL URLWithString:urlAsString];
    
    
}


#pragma mark - download

//url for downloading the note texts!

+(NSURL *) downloadURLFileContentWithHost:(NSString *)host sessionID:(NSString *)sid andPath:(NSString *)path andHttpsOn:(BOOL)httpsSelected {
    
    
    NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlAsString;
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/FileStation/file_download.cgi?api=SYNO.FileStation.Download&version=1&method=download&_sid=%@&path=%@&mode=download", host, sid, escapedPath];
        
        
    }
    else {
        
        urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/FileStation/file_download.cgi?api=SYNO.FileStation.Download&version=1&method=download&_sid=%@&path=%@&mode=download", host, sid, escapedPath];
    }
    
   // NSLog(@"Download URL as string: %@", urlAsString);
    
    
    return [NSURL URLWithString:urlAsString];
    
}

+(NSURL *)downloadURLForPhotoThumbnailWithHost: (NSString *)host sessionID: (NSString *)sid andPath: (NSString *)path andHttpsOn:(BOOL)httpsSelected {
    
    NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlAsString;
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/FileStation/file_thumb.cgi?api=SYNO.FileStation.Thumb&version=1&method=get&path=%@&_sid=%@&size=small", host, escapedPath, sid];
        
        
    }
    else {
        
        urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/FileStation/file_thumb.cgi?api=SYNO.FileStation.Thumb&version=1&method=get&path=%@&_sid=%@&size=small", host, escapedPath, sid];
    }
    
    //NSLog(@"Thumbnail URL as string: %@", urlAsString);
    
    
    return [NSURL URLWithString:urlAsString];
}

#pragma mark - upload

+(NSURL *)uploadURLwithHost: (NSString *)host andHttpsOn:(BOOL)httpsSelected {
    
    NSString *urlAsString;
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/FileStation/api_upload.cgi", host];
    }  
    
    else {
        urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/FileStation/api_upload.cgi", host];
        
    }
    
    NSString *escapedUrlAsString = [urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"upload URL: %@", escapedUrlAsString);
    
    return [NSURL URLWithString:escapedUrlAsString];
    
}

+(NSURLRequest *)urlRequestForUploadWith:(NSURL *) url fileName:(NSString *)fileName fileContent:(NSData *)fileContent AndSessionID:(NSString *)sid andFolderPath:(NSString *)folderPath {
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    //[DSNetworking addMultipartDataWithParameters:parameters toURLRequest:request];
    [request setHTTPMethod:@"POST"];

    

    char buffer[32];
    for (NSUInteger i = 0; i < 32; i++) buffer[i] = "0123456789ABCDEF"[rand() % 16];
    NSString *random = [[NSString alloc] initWithBytes:buffer length:32 encoding:NSASCIIStringEncoding];
    NSString *boundary = [NSString stringWithFormat:@"SynoClub-%@", random];

    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"api\"\r\n\r\nSYNO.FileStation.Upload"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //version
    [body appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"version\"\r\n\r\n1"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //method
    [body appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"method\"\r\n\r\nupload"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //sid
    [body appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"_sid\"\r\n\r\n%@", sid] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //folder path
    [body appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"dest_folder_path\"\r\n\r\n%@", folderPath] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //create parents
    [body appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"create_parents\"\r\n\r\ntrue"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //overwrite
    [body appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"overwrite\"\r\n\r\ntrue"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //filename & content data
    [body appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"file\"; filename=\"%@\"\r\n",fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:fileContent]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *bodyAsString = [[NSString alloc]initWithData:body encoding:NSUTF8StringEncoding];
    NSLog(@"html-body %@", bodyAsString);
    
    [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [request setHTTPShouldHandleCookies:YES];
    [request setTimeoutInterval:60];
    [request setHTTPBody:body];
    
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[body length]];
    [request addValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    
    NSLog(@"Http header fields: %@", [request allHTTPHeaderFields]);
    
    return request;
    
}

#pragma mark - delete

+(NSURL *) deleteFileURLwithHost:(NSString *)host sessionID:(NSString *)sid andPath:(NSString *)path andHttpsOn:(BOOL)httpsSelected {
    
    
    NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *urlAsString;
    
    if (httpsSelected) {
        urlAsString = [NSString stringWithFormat:@"https://%@:5001/webapi/FileStation/file_delete.cgi?api=SYNO.FileStation.Delete&version=1&method=delete&path=%@&_sid=%@", host, escapedPath, sid];
        
    }
    
    else {
        urlAsString = [NSString stringWithFormat:@"http://%@:5000/webapi/FileStation/file_delete.cgi?api=SYNO.FileStation.Delete&version=1&method=delete&path=%@&_sid=%@", host, escapedPath, sid];
        
    }
    
    return [NSURL URLWithString:urlAsString];
    
}




#pragma mark - helpers

+(id)deserializeJSONobject:(NSData *)jsonData {
    
    NSError *error;
    
    id jsonObject = [NSJSONSerialization
                     JSONObjectWithData:jsonData
                     options: NSJSONReadingAllowFragments
                     error:&error];
    
    if (jsonObject != nil && error == nil){
        
        //NSLog(@"Successfully deserialized...");
        
        if ([jsonObject isKindOfClass:[NSDictionary class]]){
            
            NSDictionary *deserializedDictionary = jsonObject;
           // NSLog(@"Deserialized JSON Dictionary = %@", deserializedDictionary);
            return deserializedDictionary;
        }
        else if ([jsonObject isKindOfClass:[NSArray class]]){
            
            NSArray *deserializedArray = (NSArray *)jsonObject;
           // NSLog(@"Deserialized JSON Array = %@", deserializedArray);
            return deserializedArray;
            
        }
        
        else {
            /* Some other object was returned. We don't know how to
             deal with this situation as the deserializer only
             returns dictionaries or arrays */
            return nil;
        }
        
    }
    
    else if (error != nil){
        NSLog(@"An error happened while deserializing the JSON data.");
    }
    return nil;
}





@end
