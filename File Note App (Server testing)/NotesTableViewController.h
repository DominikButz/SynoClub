//
//  NotesTableViewController.h
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's NSURL
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import <UIKit/UIKit.h>
@class NotesTableViewController;


@protocol NotesTableViewControllerDelegate <NSObject>

-(void)didPressLogoutButton:(NotesTableViewController *) notesVC;


@end

@interface NotesTableViewController : UITableViewController

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSString *sid; //session id

@property (nonatomic, weak) id<NotesTableViewControllerDelegate> delegate;


@end
