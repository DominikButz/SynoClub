//
//  LoginViewController.m
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import "LoginViewController.h"
#import "FXKeychain.h"
#import "DSNetworking.h"
#import "AppDelegate.h"
#import "InfoViewController.h"

#import "NotesTableViewController.h"
#import "PhotoViewController.h"

@interface LoginViewController () <NSURLSessionDelegate, NSURLSessionTaskDelegate, NotesTableViewControllerDelegate, UITextFieldDelegate, InfoViewControllerDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSString *sid;


@property (strong, nonatomic) IBOutlet UITextField *sharedFolderNameTextField;

@property (strong, nonatomic) IBOutlet UITextField *hostnameTextField;

@property (strong, nonatomic) IBOutlet UITextField *accountTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;

@property (strong, nonatomic) IBOutlet UIView *containerView;

@property (strong, nonatomic) IBOutlet UIButton *loginButton;

@property (strong, nonatomic) IBOutlet UISwitch *httpsSwitch;

@property (strong, nonatomic) IBOutlet UISwitch *stayLoggedInSwitch;


@property (strong, nonatomic) IBOutlet UISwitch *keepLoggedInSwitch;



@property (strong, nonatomic) IBOutlet UIView *loggingInStatusView;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loggingInActivityIndicator;
@property (strong, nonatomic) IBOutlet UILabel *loggingInLabel;


@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    
   
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
       
        
        
    }
    return self;
}


-(void)loadView {
    
    [super loadView];

    
}

//following methods only work because the RootNavController authorizes it
- (BOOL) shouldAutorotate
{
    return NO;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}



-(id) initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {

        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
      
        config.timeoutIntervalForRequest = 120.0;
        config.timeoutIntervalForResource = 60.0;
        config.allowsCellularAccess = YES;

     _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    
    return self;
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// uncomment to set the login credentials nil in nsuserdefaults:
    
    //[self setLoginCredentialsNil];
    
    [self.view bringSubviewToFront:self.loggingInStatusView];
    self.loggingInStatusView.layer.cornerRadius = 10;
    self.loggingInActivityIndicator.color = [UIColor whiteColor];
    
    self.containerView.layer.cornerRadius = 10;
    self.loginButton.layer.cornerRadius = 10;
    
    // conform to text field delegate to be able to implement resign first responder!
    self.hostnameTextField.delegate = self;
    self.sharedFolderNameTextField.delegate = self;
    self.accountTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    
    NSString *account = [[NSUserDefaults standardUserDefaults]objectForKey:ACCOUNT];
    NSString *host = [[NSUserDefaults standardUserDefaults] objectForKey:HOST];
    NSString *sharedFolder = [[NSUserDefaults standardUserDefaults]objectForKey:SHAREDFOLDER];
    NSString *password = [[FXKeychain defaultKeychain] objectForKey:PASSWORD];
    BOOL isHttpsOn = [[NSUserDefaults standardUserDefaults] boolForKey:HTTPS];
    BOOL stayLoggedIn = [[NSUserDefaults standardUserDefaults] boolForKey:LOGGEDIN];
    
    
    NSLog(@"it https on?%i", isHttpsOn);
    
    
    
    if (isHttpsOn == YES) {
        [self.httpsSwitch setOn:YES];
    }
    
    else {
        
        [self.httpsSwitch setOn:NO];
    }
    
    NSLog(@"keep me loggin in from SUD is on? %i", [self.stayLoggedInSwitch isOn]);
    
    
    // only if the user switched keep me logged in last time will the login be executed automatically!
    if (stayLoggedIn == YES) {
        
        [self.stayLoggedInSwitch setOn:YES];
        
        
        NSLog(@"Account: %@. Host: %@. PW: %@", account, host, password);
        
        if (account && host && password && sharedFolder) {
            
            self.hostnameTextField.text = host;
            self.sharedFolderNameTextField.text = sharedFolder;
            self.accountTextField.text = account;
            self.passwordTextField.text = password;
            
            if ([DSNetworking isFileStationWorkingForHost:host andHttpsOn:[self.httpsSwitch isOn]]) {
                
                [self loginWithAccount:account hostName:host andPW:password];
                
                
            }
            
        }
        
        
    }
    
    
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBactions

- (IBAction)loginButtonPressed:(UIButton *)sender {
    
    // check first if all fields filled!
    
    if (![self.hostnameTextField.text isEqualToString: @""] && ![self.accountTextField.text isEqualToString: @""] && ![self.passwordTextField.text isEqualToString:@""] && ![self.sharedFolderNameTextField.text isEqualToString:@""]) {
        
        //then check if File Station is running on the host
        if ([DSNetworking isFileStationWorkingForHost:self.hostnameTextField.text andHttpsOn:[self.httpsSwitch isOn]]) {
            
            ///save  both switch statuses to nsuserdefaults
            [[NSUserDefaults standardUserDefaults] setBool:[self.httpsSwitch isOn] forKey:HTTPS];
            [[NSUserDefaults standardUserDefaults] setBool:[self.stayLoggedInSwitch isOn] forKey:LOGGEDIN];
            [[NSUserDefaults standardUserDefaults]synchronize];
            
           NSLog(@"loginbuttonpressed method: is https switch enabled? %hhd ", [self.httpsSwitch isOn]);
            
            //then use login helper method (see below)
            [self loginWithAccount:self.accountTextField.text hostName:self.hostnameTextField.text andPW:self.passwordTextField.text];
            
            
        }
        
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertView *hostnameAlert = [[UIAlertView alloc] initWithTitle:@"Login failed"
                                                                        message:@"Check if your device is connected to the internet, host name is correct and that File Station is running on your DS!"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Ok"
                                                              otherButtonTitles:nil];
                [hostnameAlert show];
                NSLog(@"Check internet connection and hostname or filestation isn't running on your DS!");
                
                
            });

            
        }
        
        
    }
    
    
    else {
        
        UIAlertView *noTextAlert = [[UIAlertView alloc] initWithTitle:@"Incomplete login credentials"
                                                              message:@"You need to fill all fields"
                                                             delegate:nil
                                                    cancelButtonTitle:@"Ok"
                                                    otherButtonTitles:nil];
        [noTextAlert show];
    }
    
   
}


- (IBAction)infoButtonPressed:(UIBarButtonItem *)sender {
    NSLog(@"info button pressed method called");
    
    [self performSegueWithIdentifier:@"InfoVCSegue" sender:self];
    
}



#pragma mark - navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    
     if ([segue.identifier isEqualToString:@"toTabBarController"]) {
    //destination VC is tabbarcontroller - for notes and for photo...
    UITabBarController *tabController = segue.destinationViewController;
    
    //between tabbarcontroller and notesVC is a navigation controller:
    UINavigationController *navController = (UINavigationController *)[tabController viewControllers][0];
    NotesTableViewController *notesVC = (NotesTableViewController *)[navController viewControllers][0];
    
    
    // same for photoVC:
    UINavigationController *navController2 = (UINavigationController *)[tabController viewControllers][1];
    PhotoViewController *photoVC = (PhotoViewController *)[navController2 viewControllers][0];
    
   
        
        notesVC.delegate = self;
        notesVC.session = _session;
        notesVC.sid = _sid;
        
        photoVC.session = _session;
        photoVC.sid = _sid;
        
    }
    
    if ([segue.identifier isEqualToString:@"InfoVCSegue"]) {
        
        InfoViewController *infoVC = segue.destinationViewController;
        
        infoVC.delegate = self;
    }
    
}


#pragma mark - URLSessionDelegate method(s)


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    
     NSLog(@"executing challenge");
    
  
        
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            
           // SecCertificateRef certificate = SecTrustGetCertificateAtIndex(challenge.protectionSpace.serverTrust, 0);
        
            
        
            
            if ([challenge.protectionSpace.host isEqualToString:self.hostnameTextField.text]) {
                
                
                completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
                
                NSLog(@"set challenge protection space to server trust");
                
            }
            
          
            
        }
        
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        
    
    
}





#pragma mark - helper methods


-(void)loginWithAccount:(NSString *)account hostName:(NSString *)host andPW:(NSString *)pw {
    
    // get login url from DSNetworking class method.
    
    self.loggingInLabel.text = @"Logging in....";
    
    NSURL * loginURL = [DSNetworking loginURLwithAccount:account PW:pw host:host andSession:_session andHttpsOn:[self.httpsSwitch isOn]];
    NSLog(@"login url: %@", loginURL);
    
    self.loggingInStatusView.hidden = NO;
    [self.loggingInActivityIndicator startAnimating];
    
    NSURLSessionDataTask *loginTask = [_session dataTaskWithURL:loginURL
             completionHandler:^(NSData *data,
                                 NSURLResponse *response,
                                 NSError *error) {
                 
                 if (response !=nil) {
                     
                     NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
                     
                     if (httpResp.statusCode == 200) {
                         NSLog(@"http response status: %@", httpResp);
                         
             
                         if ([data length]>0 && error==nil) {
                         
                             NSDictionary *info = [DSNetworking deserializeJSONobject:data];
                             NSLog(@"Login-info: %@", info);
                             
                             
                             // only segue and persist login credentials if login successful!
                             if ([[info objectForKey:@"success"]  isEqual:@1]) {
                                 
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     
                                      self.loggingInLabel.text = @"Login success!";
                                     
                                 });
                                 
                                 
                                _sid = info[@"data"][@"sid"];
                                 
                                NSLog(@"SID: %@", info[@"data"][@"sid"]);
                                 
                                 // see helpers below: segue to NotesTVcontroller is in helper method
                                 [self sharedFolderExists];
                                 
                                 
                                 
                                 NSLog(@"login success -  main thread? %i", [[NSThread currentThread]isMainThread]);
                                 
                             }
                             
                             else {
                                 
                                 NSString *alertTitle = [[NSString alloc]init];
                                 NSString *message = [[NSString alloc]init];
                                 
                                 if ([info[@"error"][@"code"]  isEqual: @400]) {
                                     
                                     
                                     alertTitle = @"Login failed";
                                     message =@"Login credentials incorrect, please retry!";
                                     
                                     
                                 }
                                 
                                 else {
                                     
                                     alertTitle = @"Unknown error";
                                     message = [NSString stringWithFormat:@"An unknown error has occured - error code: %@",info[@"error"][@"code"]];
                                     
                                     
                                 }
                                 
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [self.loggingInActivityIndicator stopAnimating];
                                         self.loggingInStatusView.hidden = YES;
                                         
                                         UIAlertView *loginFailedAV = [[UIAlertView alloc] initWithTitle: alertTitle
                                                                                                          message:message
                                                                                                         delegate:nil
                                                                                                cancelButtonTitle:@"Ok"
                                                                                                otherButtonTitles:nil];
                                         [loginFailedAV show];
                                         
                                     });
                                 

                             }
                             
                             
                         }
                         
                         
                         else if ([data length] == 0 && error == nil){
                             
                             NSLog(@"No response from server, login failed");
                             
                             [self.loggingInActivityIndicator stopAnimating];
                             self.loggingInStatusView.hidden = YES;
                         }
                         
                         
                         else if (error != nil){
                             NSLog(@"Login error happened = %@", error);
                             
                             [self.loggingInActivityIndicator stopAnimating];
                             self.loggingInStatusView.hidden = YES;
                             
                         }
                         
                         
                     }
                     
                     else {
                         NSLog(@"Http response status code: %ld",(long)httpResp.statusCode);
                         
                         [self.loggingInActivityIndicator stopAnimating];
                         self.loggingInStatusView.hidden = YES;
                     }
                     
                     
                 }
                 
             }];
    
    
    [loginTask resume];
    
   }



-(void)sharedFolderExists {
    
    NSURL *url = [DSNetworking listSharedFolderURLWithHost:self.hostnameTextField.text HttpsOn:self.httpsSwitch.isOn  andSessionID:self.sid];
    
    
    __block NSMutableArray *sharedFolders = [[NSMutableArray alloc]init];
    
    self.loggingInLabel.text = @"Checking folders on DS...";
    
    [ [_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if(!error) {
            
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            NSLog(@"httpResp: %@", httpResp);
            
            if (httpResp.statusCode == 200) {
                
                
                NSDictionary *dataDic = [DSNetworking deserializeJSONobject:data];
                
                NSArray *dicArray = dataDic[@"data"][@"shares"];
                //NSLog(@"dicArray: %@", dicArray);
                
               
                    
                    for (NSDictionary *sharedFolderDic in dicArray) {
                        NSString *folderName = sharedFolderDic[@"name"];
                        [sharedFolders addObject:folderName];
                    }
                    
                   // NSLog(@"shared folders array: %@", sharedFolders);
                    
                    [[NSUserDefaults standardUserDefaults] setObject:self.sharedFolderNameTextField.text forKey:SHAREDFOLDER];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:self.hostnameTextField.text forKey:HOST];
                    [[NSUserDefaults standardUserDefaults]setObject:self.accountTextField.text forKey:ACCOUNT];
                    [[FXKeychain defaultKeychain] setObject:self.passwordTextField.text forKey:PASSWORD];
                
                     [[NSUserDefaults standardUserDefaults]synchronize];
                
               
                
                    //delete password field content for security reasons! If we segue back, user has to type in pw anew!
                    self.passwordTextField.text = @"";
                    
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.loggingInActivityIndicator stopAnimating];
                    self.loggingInStatusView.hidden = YES;

                    
                });
                
                
                    
                    if ([sharedFolders containsObject:self.sharedFolderNameTextField.text]) {
                        
                        //check if the root folder and Photos folder exist in the shared folder!
                        
                        [self appRootFolderAndPhotosFoldersExistInSharedFolder:self.sharedFolderNameTextField.text];
                        
                        
                    }
                    
                    else {
                        [DSNetworking logoutWithHost:self.hostnameTextField.text Session:self.session andSessionID:self.sid andHttpsOn:[self.httpsSwitch isOn] ];
                        

                        NSString *alertMsg =  @"Shared folder does not exist or you are not authorized to access it! Please check your write permission for the selected shared folder!";
                        
                        UIAlertView *noSharedFolderAlert = [[UIAlertView alloc] initWithTitle:@"Unable to access shared folder"
                                                                              message:alertMsg
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"Ok"
                                                                    otherButtonTitles:nil];
                        [noSharedFolderAlert show];
                        
                        
                    }
               
                
            }
            
            
            
        }
        
    }] resume];
    
}


-(void)appRootFolderAndPhotosFoldersExistInSharedFolder:(NSString *)sharedFolderName {
    
    NSURL *url = [DSNetworking listFilesInAppRootFolderWithSharedFolderName:self.sharedFolderNameTextField.text Host:self.hostnameTextField.text andHttpsOn:[self.httpsSwitch isOn] andSid:self.sid];
    
    [ [_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if(!error) {
            
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            // NSLog(@"httpResp: %@", httpResp);
            
            if (httpResp.statusCode == 200) {
                
                NSDictionary *jsonDic = [DSNetworking deserializeJSONobject:data];
                //NSLog(@"jsonDic: %@", jsonDic);
                
                if ([jsonDic[@"success"] isEqual:@1]) {
                    
                    NSMutableArray *foldersFound= [[NSMutableArray alloc]init];
                    
                    
                    //jsonDic contains another dictionary called data. this dic contains an array called files. Each element in files is a dictionary - save dictionaries in an nsArray:
                    NSArray *contentsOfRootDirectory = jsonDic[@"data"][@"files"];
                    // NSLog(@"size of contents of Root dir: %lu", (unsigned long)[contentsOfRootDirectory count]);
                    
                    //NSLog(@"contentsOfRootDirectory: %@", contentsOfRootDirectory);
                    
                    for (NSDictionary *fileInfo in contentsOfRootDirectory) {
                        //we are only interested in folders, no files!
                        if ([fileInfo[@"isdir"] boolValue]) {
                            
                            [foldersFound addObject:fileInfo[@"name"]];
                            
                        }
                        
                        
                    }
                    
                    
                    if ([foldersFound containsObject:@"Photos"]) {
                        
                        // SynoClub and Photos folders exist, segue to next VC:
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self.loggingInActivityIndicator stopAnimating];
                            self.loggingInStatusView.hidden = YES;
                            
                            [self performSegueWithIdentifier:@"toTabBarController" sender:self];
                            
                        });
                        
                        
                        
                        
                        
                    }
                    
                    else {
                        
                        [self createPhotosFolderWithAppRootFolder];
                    }
                    

                    
                }
                
                
                else { // check if error is 408. if yes, the approot folder doesn't exist, create it along with Photos folder
                    
                    if ([jsonDic[@"error"][@"code"] isEqual:@408]) {
                        
                        [self createPhotosFolderWithAppRootFolder];
                        
                    }
                    
                    else {
                        // other error!
                        NSLog(@"Error checking if root folder exists: %@", jsonDic[@"error"][@"code"]);
                        
                        [DSNetworking logoutWithHost:self.hostnameTextField.text Session:self.session andSessionID:self.sid andHttpsOn:[self.httpsSwitch isOn] ];
                        
                        
                        NSString *alertMsg = [NSString stringWithFormat: @"An error happened - error code: %@", jsonDic[@"error"][@"code"] ] ;
                        
                        UIAlertView *unknownErrorAlert = [[UIAlertView alloc] initWithTitle:@"Unknown error"
                                                                                      message:alertMsg
                                                                                     delegate:nil
                                                                            cancelButtonTitle:@"Ok"
                                                                            otherButtonTitles:nil];
                        [unknownErrorAlert show];
                        
                        
                        
                    }
                    
                    
                    
                    
                }
                
                
                
                
            }
            
            
            
        }
        
    }] resume];
    
    
    
}

-(void) createPhotosFolderWithAppRootFolder {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.loggingInLabel.text = @"Creating folders...";
        
    });
    
    
    __block NSString *path = [NSString stringWithFormat:@"%@/%@", appFolder, photoFolder];
    
    NSURL *url = [DSNetworking createAppFoldersWithHost:self.hostnameTextField.text sessionID:self.sid SharedFolder:self.sharedFolderNameTextField.text FolderPath:path andHttpsOn:[self.httpsSwitch isOn]];
    
    [ [_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if(!error) {
            
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            // NSLog(@"httpResp: %@", httpResp);
            
            if (httpResp.statusCode == 200) {
                
                NSDictionary *dataResponse = [DSNetworking deserializeJSONobject:data];
                //NSLog(@"data Response:%@", dataResponse);
            
                NSArray *foldersArray = dataResponse[@"data"][@"folders"];
                //NSLog(@"folders array: %@", foldersArray);
                
                NSDictionary *firstDic = foldersArray[0];
                //NSLog(@"first dic in folders array: %@", firstDic);
                
                if ([firstDic[@"path"] isEqualToString:[NSString stringWithFormat:@"/%@/%@", self.sharedFolderNameTextField.text, path]]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [self.loggingInActivityIndicator stopAnimating];
                        self.loggingInStatusView.hidden = YES;
                        
                        [self performSegueWithIdentifier:@"toTabBarController" sender:self];
                        
                    });
                    
                    
                    
                    
                }
                
                else {
                    
                    
                    
                    NSLog(@"Error: app folders could not be created! %@", dataResponse[@"error"][@"code"]);
                    
                }
                
            }
            
            
            else {
                
                 NSLog(@"Error: app folders could not be created - %@!", error);
            }
            
            
            
        }
        
    }] resume];
    
    
}


// set NSuserdefaults objects and FXkeychain object nil for login testing purpose
-(void)setLoginCredentialsNil {
    
    NSString *account = [[NSUserDefaults standardUserDefaults]objectForKey:ACCOUNT];
    NSString *host = [[NSUserDefaults standardUserDefaults] objectForKey:HOST];
    NSString *password = [[FXKeychain defaultKeychain] objectForKey:PASSWORD];
    
    if (account && host && password) {
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACCOUNT];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:HOST];
        [[FXKeychain defaultKeychain]removeObjectForKey:PASSWORD];
        [[NSUserDefaults standardUserDefaults]synchronize];
        
        }
    
    
}

#pragma mark - NotesTVC delegate methods

-(void)didPressLogoutButton:(NotesTableViewController *)notesVC {
    
    
    NSString *hostName = [[NSUserDefaults standardUserDefaults] objectForKey:HOST];
    
    BOOL success = [DSNetworking logoutWithHost:hostName Session:_session andSessionID:_sid andHttpsOn:[self.httpsSwitch isOn]];
    
   // [[NSUserDefaults standardUserDefaults]setBool:[self.httpsSwitch isOn] forKey:HTTPS];
    
    NSLog(@"success: %i", success);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
    
}

#pragma mark - UITextfieldDelegate

-(BOOL) textFieldShouldReturn: (UITextField *) textField
{
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - Info VC Delegate

-(void)didPressDoneButton {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}








@end
