//
//  NoteDetailsViewController.h
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import <UIKit/UIKit.h>
#import "DSFile.h"

@class DSFile;
@class NoteDetailsViewController;

//protocol with methods: need to inform the notesVC when cancel or done was pressed in the notedetailsvc. 
@protocol NoteDetailsViewControllerDelegate <NSObject>

-(void)noteDetailsVCdidCancel:(NoteDetailsViewController *)controller;
-(void)noteDetailsVCdoneWithDetails:(NoteDetailsViewController *)controller;

@end


@interface NoteDetailsViewController : UITableViewController

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSString *sid;
@property (strong, nonatomic) DSFile *note;

@property (nonatomic, weak) id<NoteDetailsViewControllerDelegate> delegate;

@end
