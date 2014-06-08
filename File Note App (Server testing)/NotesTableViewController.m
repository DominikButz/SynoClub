//
//  NotesTableViewController.m
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import "NotesTableViewController.h"
#import "DSFile.h"
#import "DSNetworking.h"
#import "NoteDetailsViewController.h"

NSString *const exampleNoteTitle = @"Example note";


@interface NotesTableViewController () <NoteDetailsViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray *notes;
@property (strong, nonatomic) NSString *hostName;
@property (nonatomic) BOOL HTTPSIsOn;
@property (nonatomic, strong) NSString *sharedFolderName;



@end

@implementation NotesTableViewController



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textSizeChangedWithNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil] ;
    
      self.sharedFolderName = [[NSUserDefaults standardUserDefaults] objectForKey:SHAREDFOLDER];
      self.hostName = [[NSUserDefaults standardUserDefaults] objectForKey:HOST];
      self.HTTPSIsOn = [[NSUserDefaults standardUserDefaults] boolForKey:HTTPS];


    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    if (_session) {
//        
//    
//    NSLog(@"Session:%@", _session);
//        
//    }
    
    [self downloadNotesFromFileStation];
    
}


-(void)textSizeChangedWithNotification:(NSNotification *) notification {
    
    [self.tableView reloadData];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:YES];
    
    [self downloadNotesFromFileStation];
    
}


-(void)downloadNotesFromFileStation {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
  
    
    NSURL *url = [DSNetworking listFilesInAppRootFolderWithSharedFolderName:self.sharedFolderName Host:self.hostName andHttpsOn:self.HTTPSIsOn andSid:self.sid];
    
   // NSLog(@"url of root folder: %@", url);
   [ [_session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
           // NSLog(@"httpResp: %@", httpResp);
            
            if (httpResp.statusCode == 200) {
                
                NSDictionary *jsonDic = [DSNetworking deserializeJSONobject:data];
                //NSLog(@"jsonDic: %@", jsonDic);
                
                NSMutableArray *notesFound = [[NSMutableArray alloc]init];
                
                
                //jsonDic contains another dictionary called data. this dic contains another dic called files. Each element in files is a dictionary - save dictionaries in an nsArray:
                NSArray *contentsOfRootDirectory = jsonDic[@"data"][@"files"];
               // NSLog(@"size of contents of Root dir: %lu", (unsigned long)[contentsOfRootDirectory count]);
                
               //NSLog(@"contentsOfRootDirectory: %@", contentsOfRootDirectory);
                
                for (NSDictionary *fileInfo in contentsOfRootDirectory) {
                    //we are only interested in files, no directories!
                    if (![fileInfo[@"isdir"]boolValue]) {
                        
                        DSFile *note = [[DSFile alloc]initWithJSONData:fileInfo];
                        //NSLog(@"modified date:%@", note.modified);
                        [notesFound addObject:note];
                        
                    }
                    
                }
                
                
                //sort notes and refresh table view only if notesFound array isn't empty
                
                if ([notesFound count] != 0 ) {
                    
                    [notesFound sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                        return [obj1 compare:obj2];
                        
                    }];
                    
                    
                    // copy sorted notesFound-array into the notes array that has been set up as property
                    
                    self.notes = notesFound;
                    
                    
                    
                    // UI update must be done on the  main queue!
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        [self.tableView reloadData ];
                        
                        
                    });
                    
                    
                    
                }
                
                //if there are no notes, upload a test note but only if the user didn't delete the example note before!
                else {
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    
                    if (![[NSUserDefaults standardUserDefaults] boolForKey:EXAMPLENOTEDELETED]) {
                        
                        
                        [self uploadExampleNote];
                        
                    }
                    
                    
                    
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


-(void)deleteNoteAsDSFile: (DSFile *)file {
    
    
    
    NSURL *fileURL = [DSNetworking deleteFileURLwithHost:self.hostName sessionID:_sid andPath:file.path andHttpsOn:self.HTTPSIsOn];
    
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
                            message = @"Server error code: 407 - operation not permitted. There might be a problem with your user account permission settings or you don't have access to the public folder or Photos sub folder. Please contact the server administrator.";
                        }
                        else {
                            
                            message = [NSString stringWithFormat:@"Server error code: %@. Please contact the server administrator.", errorCode];
                        }
                        
                        
                        UIAlertView *serverErrorAlert = [[UIAlertView alloc]initWithTitle:@"Delete operation failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        
                        [serverErrorAlert show];
                        
                        
                    });
                    
                    
                    
                }
                
                
                else {
                    
                    if ([file.name isEqualToString:exampleNoteTitle]) {
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:EXAMPLENOTEDELETED];
                        
                       
                        
                    }
                    
                    else {
                        
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:EXAMPLENOTEDELETED];
                    }
                    
                     [[NSUserDefaults standardUserDefaults] synchronize];
                    
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

#pragma mark - navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    
    
    UINavigationController *navController = segue.destinationViewController;
    
    NoteDetailsViewController *detailsVC = (NoteDetailsViewController *)[navController viewControllers][0];
    
    detailsVC.session = _session;
    detailsVC.sid = _sid;
    
    detailsVC.delegate = self;
    
    if ([segue.identifier isEqualToString:@"editNote"]) {
        
        DSFile *note =  _notes[[self.tableView indexPathForSelectedRow].row];
        
        detailsVC.note =note;
        
        
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
   // NSLog(@"number of rows: %lu", (unsigned long)[_notes count]);

    // Return the number of rows in the section.
    return [_notes count];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NoteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    DSFile *note = _notes[indexPath.row];
    
    //set font type as dynamic type
    UIFont *font =[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    //set text color
    UIColor *textColor = [UIColor colorWithRed:65.0/255 green:127.0/255 blue:6.0/255 alpha:1.0];
    
    // add attribues to dictionary including additional feature (letterpress -style)
    NSDictionary *attrs = @{NSForegroundColorAttributeName : textColor,
                            NSFontAttributeName : font,
                            NSTextEffectAttributeName : NSTextEffectLetterpressStyle};
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[note fileNameShowExtension:NO] attributes:attrs];
    
  
    cell.textLabel.attributedText = attrString;
    // Configure the cell...
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        //NSLog(@"notes in self.notes: %lu",(unsigned long)[self.notes count]);
        // save dsfile to delete on server first and remove it from array afterwards!
        DSFile *fileToDelete = self.notes[indexPath.row];
        
        [self.notes removeObjectAtIndex:indexPath.row];
        
        NSLog(@"indexpath.row: %li", (long)indexPath.row);
        
        // then hand the saved dsfile to the deleteNote..-method to execute deletion on server:
         [self deleteNoteAsDSFile:fileToDelete];
        
        //finally delete the row from the tableview:
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
    
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - UI Table View Delegate


// adjust the row height dynamically according to the font size of the note titles
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // create a label with text  to use it as a frame that adapts automatically to the font size
    static UILabel* label;
    if (!label) {
        label = [[UILabel alloc]
                 initWithFrame:CGRectMake(0, 0, FLT_MAX, FLT_MAX)];
        label.text = @"test";
    }
    
    // set the preferred font text style to the label's font, then tell the label to fit tightly around the text. the label's frame height is used as baseline for the row height (times a chosen factor)
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    [label sizeToFit];
    return label.frame.size.height * 1.7;
    
}


#pragma mark - NoteDetailsVC delegate methods

-(void)noteDetailsVCdidCancel:(NoteDetailsViewController *)controller {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

-(void)noteDetailsVCdoneWithDetails:(NoteDetailsViewController *)controller {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self downloadNotesFromFileStation];
}

#pragma mark - IB action

- (IBAction)logoutButtonPressed:(UIBarButtonItem *)sender {
   
    [self.delegate didPressLogoutButton:self];
    
}

#pragma  mark - helper method(s)

-(void)uploadExampleNote {
    

    NSString *exampleNoteText = @"This is an example note. Feel free to change this text. Notes are saved as files on your Synology DS. If you change the note title, the note will be uploaded as a new file";
    
    //convert note text to nsdata
    NSData *exampleNoteTextAsData = [exampleNoteText dataUsingEncoding:NSUTF8StringEncoding];
    
    
    // exampleNoteTitle is a constant defined in header of this m-file!
    NSURL *url = [DSNetworking uploadURLwithHost:self.hostName andHttpsOn:self.HTTPSIsOn];
    NSString *folderPath = [NSString stringWithFormat:@"/%@/%@", self.sharedFolderName, appFolder];
    
    NSURLRequest *request = [DSNetworking urlRequestForUploadWith:url fileName:exampleNoteTitle fileContent:exampleNoteTextAsData AndSessionID:self.sid andFolderPath:folderPath];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSURLSessionDataTask *dataTask = [_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        
        
        NSDictionary *dataDic = [DSNetworking deserializeJSONobject:data];
        
        
        if (!error) {
            
            if (httpResp.statusCode == 200) {
                
                if ([dataDic[@"success"] isEqual:@1]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        
                        [self downloadNotesFromFileStation];
                        
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    });
                    
                    
                    
                }
                
                else {
                    
                    NSLog(@"Problem on server side:%@", dataDic[@"error"][@"code"]);
                    
                    NSNumber *errorCode = dataDic[@"error"][@"code"];
                    
                    // uialertview on main queue:
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
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
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            }
            
        }
        
        else {
            
            
            NSLog(@"Error:%@",error);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
        
    }];
    
    [dataTask resume];

    
    
}



@end
