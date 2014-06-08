//
//  NoteDetailsViewController.m
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import "NoteDetailsViewController.h"
#import "DSNetworking.h"


@interface NoteDetailsViewController ()


@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (weak, nonatomic) IBOutlet UITextField *challengeNameTextField;
@property (weak, nonatomic) IBOutlet UITextView *noteTextField;
@property (strong, nonatomic) NSString *hostName;
@property (nonatomic) BOOL HTTPSIsOn;
@property (strong, nonatomic) NSString *sharedFolderName;


@end

@implementation NoteDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self){
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textSizeChangedWithNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil] ;
    
    self.hostName = [[NSUserDefaults standardUserDefaults] objectForKey:HOST];
    self.HTTPSIsOn = [[NSUserDefaults standardUserDefaults] boolForKey:HTTPS];
    self.sharedFolderName = [[NSUserDefaults standardUserDefaults] objectForKey:SHAREDFOLDER];
    // there will be a DSFile-note handed over from the NotesTableVC but only if a note was selected from the table view in the notesTVC (not if the add button was pressed!). If there is a note, set the notes name to the challenge name text field
    if (self.note) {
        self.challengeNameTextField.text = self.note.name;
        [self retrieveNoteText];
    }
    
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)retrieveNoteText {
    
   
    
    NSString *notePath = self.note.path;
    
    NSURL *url = [DSNetworking downloadURLFileContentWithHost:self.hostName sessionID:self.sid andPath:notePath andHttpsOn:self.HTTPSIsOn];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if (httpResp.statusCode == 200) {
                
                NSString *noteText = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                //NSLog(@"Note Text = %@ ", noteText);
                
                      dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    
                    self.noteTextField.text = noteText;
                    
                });
            
                }
            else {
                
                UIAlertView *badResponseAlert = [[UIAlertView alloc]initWithTitle:@"Bad server response" message:[NSString stringWithFormat:@"Unable to retrieve the challenge text. Error code:%ld", (long)httpResp.statusCode] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [badResponseAlert show];
                
            }
            
            
        }
        
        else {
            
            UIAlertView *serverConnectionAlert = [[UIAlertView alloc]initWithTitle:@"Server connection failed" message:[NSString stringWithFormat:@"Unable to connect to server. Error :%@", error] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [serverConnectionAlert show];
            
        }
        
    }]resume];
    
    
}


#pragma mark - IBActions
// upload if done button pressed
- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender {
    
    //neither field can be empty!
    if (![self.challengeNameTextField.text isEqualToString: @""] && ![self.noteTextField.text isEqualToString: @""]) {
        
        //check if we're adding a new note
        if (!self.note) {
            DSFile *newNote = [[DSFile alloc]init];
            self.note = newNote;
        }
        
        
        _note.name = self.challengeNameTextField.text;
        _note.contents = self.noteTextField.text;
        
        
        //convert note text to nsdata
       NSData *noteContents = [_note.contents dataUsingEncoding:NSUTF8StringEncoding];
        
        
        
        NSURL *url = [DSNetworking uploadURLwithHost:self.hostName andHttpsOn:self.HTTPSIsOn];
        NSString *folderPath = [NSString stringWithFormat:@"/%@/%@", self.sharedFolderName, appFolder];
        
        NSURLRequest *request = [DSNetworking urlRequestForUploadWith:url fileName:_note.name fileContent:noteContents AndSessionID:self.sid andFolderPath:folderPath];
        
        NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
     
            
            NSDictionary *dataDic = [DSNetworking deserializeJSONobject:data];

            
            if (!error) {
            
                if (httpResp.statusCode == 200) {
                    
                    if ([dataDic[@"success"] isEqual:@1]) {
                        
                            [self.delegate noteDetailsVCdoneWithDetails:self];
                    
                    }
                    
                    else {
                        
                        NSLog(@"Problem on server side:%@", dataDic[@"error"][@"code"]);
                        
                        NSNumber *errorCode = dataDic[@"error"][@"code"];
                        
                        // uialertview on main queue:
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *message = [[NSString alloc]init];
                            if ([errorCode  isEqual: @407]) {
                                message = @"Server error code: 407 - operation not permitted. You probably do not have write permission for the destination folder on your DS. Please contact the server administrator.";
                            }
                            else {
                                
                                message = [NSString stringWithFormat:@"Server error code: %@. Please contact the server administrator.", errorCode];
                            }
                            
                            
                            UIAlertView *serverErrorAlert = [[UIAlertView alloc]initWithTitle:@"Upload failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            
                            [serverErrorAlert show];
                        });
                        
                        
                    }
                }
                
                else {
                    
                    NSLog(@"httpresp-Status code: %ld", (long)httpResp.statusCode);
                }
            
            }
            
             else {
            
          
                NSLog(@"Error:%@",error);
            }
            
        }];
        
        [dataTask resume];
        

        
    }
    
    
    else {
        
        UIAlertView *noTextAlert = [[UIAlertView alloc] initWithTitle:@"No text"
                                                              message:@"You need to fill all fields"
                                                             delegate:nil
                                                    cancelButtonTitle:@"Ok"
                                                    otherButtonTitles:nil];
        [noTextAlert show];

    }
    
}




- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    
    [self.delegate noteDetailsVCdidCancel:self];
    
}


-(void)textSizeChangedWithNotification:(NSNotification *)notification {
    
    [_challengeNameTextField setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
     
    [_noteTextField setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
    
}



    

@end
