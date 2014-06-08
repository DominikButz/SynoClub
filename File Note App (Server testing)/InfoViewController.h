//
//  InfoViewController.h
//  SynoClub
//
//  Created by Dominik Butz on 01/06/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfoViewControllerDelegate <NSObject>

-(void)didPressDoneButton;

@end

@interface InfoViewController : UIViewController

@property (weak, nonatomic) id<InfoViewControllerDelegate> delegate;

@end
