//
//  PhotoViewController.m
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import "PhotoViewController.h"
#import "DSNetworking.h"
#import "DSFile.h"
#import "PhotoCell.h"
#import "PhotoDetailViewController.h"

@interface PhotoViewController () <UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate, NSURLSessionTaskDelegate, NSURLSessionDelegate, PhotoDetailViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *photoFilesInfo;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UIView *uploadView;
@property (strong, nonatomic) NSString *hostName;
@property (nonatomic) BOOL HTTPSIsOn;
@property (strong, nonatomic) NSString *sharedFolderName;


@property (nonatomic, strong) NSURLSessionDataTask *uploadTask; // can't use nsurlsessionupload task because apache file server requires data to be sent in html body with post request!



@end

@implementation PhotoViewController 


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // 1
        
       
        
    }
    return self;
}




- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //get URL parameter values from NSUserDefaults:
    self.hostName = [[NSUserDefaults standardUserDefaults] objectForKey:HOST];
    self.HTTPSIsOn = [[NSUserDefaults standardUserDefaults] boolForKey:HTTPS];
    self.sharedFolderName = [[NSUserDefaults standardUserDefaults] objectForKey:SHAREDFOLDER];
    
    self.uploadView.layer.cornerRadius = 10.0;
    
    [self refreshPhotosFromFileStation];
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:YES];
    [self refreshPhotosFromFileStation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refreshPhotosFromFileStation {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURL *url = [DSNetworking listPhotosInPhotoFolderWithSharedFolderName:self.sharedFolderName Host:self.hostName andHttpsOn:self.HTTPSIsOn andSid:self.sid];
    
    //NSLog(@"is https on? %hhd", self.HTTPSIsOn);
    
     NSLog(@"url of photo folder: %@", url);
    [ [_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            // NSLog(@"httpResp: %@", httpResp);
            
            if (httpResp.statusCode == 200) {
                
                NSDictionary *jsonDic = [DSNetworking deserializeJSONobject:data];
                //NSLog(@"jsonDic: %@", jsonDic);
                
                NSMutableArray *photosFound = [[NSMutableArray alloc]init];
                
                
                //jsonDic contains another dictionary called data. this dic contains another dic called files. Each element in files is a dictionary - save dictionaries in an nsArray:
                NSArray *contentsOfPhotoDirectory = jsonDic[@"data"][@"files"];
                // NSLog(@"size of contents of Root dir: %lu", (unsigned long)[contentsOfRootDirectory count]);
                
                //NSLog(@"contentsOfPhotoDirectory: %@", contentsOfPhotoDirectory);
                
                //make sure the Photos folder is not empty!
                if ([contentsOfPhotoDirectory count] !=0 ) {
                    
                
                    for (NSDictionary *fileInfo in contentsOfPhotoDirectory) {
                    
                    //we are only interested in files, no directories and only jpg and png files are allowed!
                        if (![fileInfo[@"isdir"]boolValue] && [self isJpgOrPngFile:fileInfo[@"name"]] ) {
                        
                            DSFile *photoInfo = [[DSFile alloc]initWithJSONData:fileInfo];
                            //NSLog(@"modified date:%@", photo.modified);
                            [photosFound addObject:photoInfo];
                        
                        }
                    
                    }
                
                
                    //sort notes alphabetically (?)
                    [photosFound sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    return [obj1 compare:obj2];
                    
                    }];
                
                
                    // copy sorted notesFound-array into the notes array that has been set up as property
                
                    self.photoFilesInfo = photosFound;
                    // NSLog(@"photo Files Info: %@", self.photoFilesInfo);
                    DSFile *firstphoto = self.photoFilesInfo[0];
                    NSLog(@"path of first photo: %@", firstphoto.path );
                
                    // UI update must be done on the  main queue!
                    dispatch_async(dispatch_get_main_queue(), ^{
                    //NSLog(@"sid in refresh photo method pos 1234: %@", _sid);
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        [self.tableView reloadData ];
                    
                    
                    });
                    
                }
                
            }
            
            //other than status 200!
            else{
                NSLog(@"http status code:%ld", (long)httpResp.statusCode);
                
            }
            
            
            
        }
        
        //if error:
        else {
            
            NSLog(@"Error: %@", error);
        }
        
        // don't forget to resume!
    }]resume];
    
    
    
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_photoFilesInfo count];
    NSLog(@"number of rows in section %lu", (unsigned long)[_photoFilesInfo count]);
    
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"PhotoCell";
    PhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    DSFile *photoInfo = _photoFilesInfo[indexPath.row];
    
   // NSLog(@"photo Info path:%@", photoInfo.path);
    
    NSString *hostName = [[NSUserDefaults standardUserDefaults]objectForKey:HOST];
    BOOL httpsOn = [[NSUserDefaults standardUserDefaults] boolForKey:HTTPS];
    
    NSURL *thumbnailDownloadURL = [DSNetworking downloadURLForPhotoThumbnailWithHost:hostName sessionID:_sid andPath:photoInfo.path andHttpsOn:httpsOn];
    
    //NSLog(@"thumbnail download url: %@", thumbnailDownloadURL);
    
    
    if (self.tableView.dragging == NO && self.tableView.decelerating == NO) {
        
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURLSessionDataTask *dataTask = [_session dataTaskWithURL:thumbnailDownloadURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            // NSLog(@"httpResp: %@", httpResp);
            if (httpResp.statusCode == 200) {
                
               
                
                
                    
                    //get thumbnail as data, convert to uiimage
                    UIImage *thumbnailImage = [[UIImage alloc]initWithData:data];
                    
                    //set thumbNail-property to the downloaded image
                    photoInfo.thumbNail = thumbnailImage;
                    
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        // updating the cell
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
                        cell.thumbnailImageView.image = photoInfo.thumbNail;
                        
                    });
                
                
                
            }
            
            else {
                
                NSLog(@"httpresp-Status code: %ld", (long)httpResp.statusCode);
            }
            
        }
        
        else {
            
            //error handling
            NSLog(@"Error:%@",error);
        }
        
                
    }];
                                      
    [dataTask resume];
    }
    return cell;
    
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
       DSFile *photoToDelete =  [self.photoFilesInfo objectAtIndex:indexPath.row];
        
        [self.photoFilesInfo removeObjectAtIndex:indexPath.row];
        
        [self deletePhoto:photoToDelete];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
}

#pragma mark - pick image and upload

- (IBAction)cameraBarButtonItemPressed:(UIBarButtonItem *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.allowsEditing = NO;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self uploadImage:image];
    
    
}

- (IBAction)uploadCancelButtonPressed:(UIButton *)sender {
    
    
    self.uploadView.hidden = YES;
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
    
    if (_uploadTask.state == NSURLSessionTaskStateRunning) {
        [_uploadTask cancel];
        
    }
    
}

-(void) uploadImage: (UIImage *) image {
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    
    NSURL *uploadURL =  [DSNetworking uploadURLwithHost:self.hostName andHttpsOn:self.HTTPSIsOn];
    
    NSString *photoFolderPath = [NSString stringWithFormat:@"/%@/%@/%@", self.sharedFolderName, appFolder, photoFolder];
    NSLog(@"photofolder path for upload: %@", photoFolderPath);
    
    NSString *fileName = [self photoFileNameFromNSArray:self.photoFilesInfo]; // create filenames dynamically with helper method (see below)
    
    NSURLRequest *request = [DSNetworking urlRequestForUploadWith:uploadURL fileName:fileName fileContent:imageData AndSessionID:_sid andFolderPath:photoFolderPath];
    
    //Previously, we used the session set up in initWithCoder and the associated convenience methods to create asynchronous tasks. This time, we’re using an NSURLSessionConfiguration that only permits one connection to the remote host, since our upload process handles just one file at a time.
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    config.timeoutIntervalForRequest = 60.0;
    config.timeoutIntervalForResource = 100.0;
    config.allowsCellularAccess = YES;
    config.HTTPMaximumConnectionsPerHost = 1;
    // also create new session for this upload task!
    NSURLSession *newSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
   
    
    // set upload view unhidden and network activity indicator active as upload begins... will be set hidden again in nsurlsessiontask delegate methods (see below)
    self.uploadView.hidden = NO;
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
    
    _uploadTask = [newSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        NSLog(@"upload photo httpResp:%@", httpResp);
        //
        NSDictionary *dataDic = [DSNetworking deserializeJSONobject:data];
        NSLog(@"upload photo response Data %@", dataDic);
        //
        if (!error &&  httpResp.statusCode == 200) {
            
            NSLog(@"status code 200");
            
            NSLog(@"dataDic success: %@", [dataDic[@"success"]class] );
            
            //BOOL success = (BOOL)dataDic[@"success"];
            
            // class of the success value is NSCFBoolean, the typedef of NSNumber. So need to compare with @0 or @1.
            if ([dataDic[@"success"]  isEqual: @0]) {
                
                
                NSLog(@"Problem on server side:%@", dataDic[@"error"][@"code"]);
                
                NSNumber *errorCode = dataDic[@"error"][@"code"];
                
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSString *message = [[NSString alloc]init];
                    if ([errorCode  isEqual: @407]) {
                        message = @"Server error code: 407 - operation not permitted. There might be a problem with your user account permission settings. Please contact the server administrator.";
                    }
                    else {
                        
                        message = [NSString stringWithFormat:@"Server error code: %@. Please contact the server administrator.", errorCode];
                    }
                    [_progress setProgress:0 animated:NO];
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                    _uploadView.hidden = YES;

                    
                    UIAlertView *serverErrorAlert = [[UIAlertView alloc]initWithTitle:@"Upload failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    
                    [serverErrorAlert show];
                });
                
               
                
                
                
               
            }
            
            // this executes if succes is true, so upload was successful:
            
            else {
                
            dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            _uploadView.hidden = YES;
             });
                
            }
            
        }
        
        else {
            
            //error handling
            NSLog(@"Error:%@ --  status code: %ld",error, (long)httpResp.statusCode);
        }
        
    }];
                   
    [_uploadTask resume];
    
    
}


-(void)deletePhoto: (DSFile *)photoInfo{
    
    
    NSURL *fileURL = [DSNetworking deleteFileURLwithHost:self.hostName sessionID:_sid andPath:photoInfo.path andHttpsOn:self.HTTPSIsOn];
    
    NSURLSessionDataTask *deleteTask = [_session dataTaskWithURL:fileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if (httpResponse.statusCode == 200) {
                
                
                NSDictionary *dataDic = [DSNetworking deserializeJSONobject:data];
                NSLog(@"datadict: %@", dataDic);
                
                //there should be no response. if there is, something went wrong:
                if (![dataDic[@"success"]  isEqual: @1]) {
                    
                    NSLog(@"Problem on server side:%@", dataDic[@"error"][@"code"]);
                    
                    NSNumber *errorCode = dataDic[@"error"][@"code"];
                    
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString *message = [[NSString alloc]init];
                        if ([errorCode  isEqual: @407]) {
                            message = @"Server error code: 407 - operation not permitted. There might be a problem with your user account permission settings. Please contact the server administrator.";
                        }
                        else {
                            
                            message = [NSString stringWithFormat:@"Server error code: %@. Please contact the server administrator.", errorCode];
                        }
                        
                        
                        UIAlertView *serverErrorAlert = [[UIAlertView alloc]initWithTitle:@"Delete operation failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        
                        [serverErrorAlert show];
                        
                        
                    });
                    
                    
                    
                }
                
            }
            
            else {
                
                NSLog(@"Status code response: %ld", (long)httpResponse.statusCode);
            }
            
            
            
            
        }
        
        else {
            
            NSLog(@"An error happened: %@", error);
        }
        
        
    }];
    
    [deleteTask resume];
    
    
}


#pragma mark - NSURLSessionTaskDelegate methods

//The below delegate method periodically reports information about the upload task back to the caller. It also updates UIProgressView (_progress) to show totalBytesSent / totalBytesExpectedToSend which is more informative (and much geekier) than showing percent complete.
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    NSLog(@"did send body data method called");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_progress setProgress:(double)totalBytesSent / (double)totalBytesExpectedToSend animated:YES];
    });
    
}



-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    NSLog(@"task did complete with error message called");
    dispatch_async(dispatch_get_main_queue(), ^{
        //Turns off the network activity indicator and then hides the _uploadView as a bit of cleanup once the upload is done.
        [_progress setProgress:0.5];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        _uploadView.hidden = YES;
        
    });
    
    if (!error) {
        //Refresh PhotosViewController table view to include uploaded photo
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshPhotosFromFileStation];
        });
        
    }
    
    else {
        
        // error alert
    }
    
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    PhotoDetailViewController *photoDetailVC = segue.destinationViewController;
    
    photoDetailVC.session = self.session;
    photoDetailVC.sid = self.sid;
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    DSFile *photoInfo = self.photoFilesInfo[indexPath.row];
    
    photoDetailVC.photoFileInfo = photoInfo;
    
    photoDetailVC.delegate = self;
    
    
}


#pragma mark - helpers

-(BOOL)isJpgOrPngFile: (NSString *)fileName {
    
    NSString *imageType = [[[fileName componentsSeparatedByString:@"."]lastObject]lowercaseString] ;
    
    
    if ( [imageType isEqualToString:@"jpg"] || [imageType isEqualToString:@"png"] ){
        return YES;
    }
    else return NO;
    
}

-(NSString *)photoFileNameFromNSArray:(NSArray *)array {
    NSMutableArray *photoFileNames = [[NSMutableArray alloc]init];
    //copy the name of each dsfile into a new array
    for (DSFile *file in array) {
        [photoFileNames addObject:file.name ];
    }
    //first photo name ends with index 1
    int i = 1;
    
     NSString *photoFileName = [NSString stringWithFormat:@"SynoClub_photo_%i.jpg", i];
    
    // check if the file name already exists
    while ([photoFileNames containsObject:photoFileName]) {
        
        i++;
        photoFileName = [NSString stringWithFormat:photoFileName, i];
    }
    
    //index incremented as long as the file name already exists. new file name's index is the last file name index plus 1!
    
    return photoFileName;
}


#pragma mark - PhotoDetailVC delegate

-(void)didPressBackButton:(PhotoDetailViewController *)photoDetailVC {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}



#pragma mark - nsurlsession delegate

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    
    
    
    if(task.state == NSURLSessionTaskStateRunning)
    {
        
        
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            
            // SecCertificateRef certificate = SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, 0);
            
            
            
            if ([challenge.protectionSpace.host isEqualToString:self.hostName]) {
                
                
                completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                
            }
            
            
        }
        
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        
    }
    
}




@end
