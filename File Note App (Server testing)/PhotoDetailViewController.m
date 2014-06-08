//
//  PhotoDetailViewController.m
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial


#import "PhotoDetailViewController.h"
#import "DSNetworking.h"
#import "DACircularProgressView.h"

@interface PhotoDetailViewController () <UIScrollViewDelegate, NSURLSessionDownloadDelegate>



@property (strong, nonatomic) NSString *hostName;
@property (nonatomic) BOOL HTTPSIsOn;
@property (strong, nonatomic) NSString *sharedFolderName;
@property (weak, nonatomic) IBOutlet DACircularProgressView *circularProgressView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *backBarButtonItem;


@end

@implementation PhotoDetailViewController

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
    //self.imageScrollView.delegate = self;
    self.backBarButtonItem.tintColor = [UIColor colorWithRed:65.0/255 green:127.0/255 blue:6.0/255 alpha:1.0];
   
    [self.view bringSubviewToFront:self.circularProgressView];
    
    self.hostName = [[NSUserDefaults standardUserDefaults] objectForKey:HOST];
    self.HTTPSIsOn = [[NSUserDefaults standardUserDefaults] boolForKey:HTTPS];
	self.sharedFolderName = [[NSUserDefaults standardUserDefaults] objectForKey:SHAREDFOLDER];

    
    [self downloadPhoto];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - photo download

-(void) downloadPhoto {
    
    
    NSString *photoPath = self.photoFileInfo.path;
    NSLog(@"photo Path for download: %@", photoPath);
    NSLog(@"sid: %@", self.sid);
    
    NSURL *url = [DSNetworking downloadURLFileContentWithHost:self.hostName sessionID:self.sid andPath:photoPath andHttpsOn:self.HTTPSIsOn];
    
    
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    config.timeoutIntervalForRequest = 150.0;
    config.timeoutIntervalForResource = 150.0;
    config.allowsCellularAccess = YES;
    config.HTTPMaximumConnectionsPerHost = 1;
    // also create new session for this upload task!
   NSURLSession *downloadSession =  [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    
    // no completion block - we're using the delegate methods below to receive data & for error handling!
    NSURLSessionDownloadTask *downloadTask = [downloadSession downloadTaskWithRequest:request];
    
    
    [downloadTask resume];
    


    
}


- (IBAction)backButtonPressed:(UIBarButtonItem *)sender {
    
    NSLog(@"back button pressed");
    [self.delegate didPressBackButton:self];
    
}


#pragma mark - ScrollView delegate
///* We implement the UIScrollView delegate method so that the UIScrollView delegate will know which view on its' scrollview to zoom into and out of. */
//-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
//	return self.imageView;
//}


#pragma mark - NSURLSessionDownload-Delegate methods

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.circularProgressView setProgress:(double)totalBytesWritten / (double)totalBytesExpectedToWrite animated:YES];
        
    });
    
    
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
    
    UIImage *downloadedImage = [UIImage imageWithData: [NSData dataWithContentsOfURL:location]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.circularProgressView setProgress:1.0];
        self.circularProgressView.hidden = YES;
        self.imageView.image = downloadedImage;
        
        
        
        
    });
    
}



@end
