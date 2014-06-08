//
//  AppDelegate.m
//  SynoClub
//
//  Created by Dominik Butz on 6/4/14.
//  Copyright (c) 2014 Dominik Butz. All rights reserved.

//A major part of this example app (using the Synology FileStation API) has been taken from Ray Wenderlich's
// NSURLSession-tutorial http://www.raywenderlich.com/51127/nsurlsession-tutorial
//Special thanks to Ray Wenderlich and Charlie Fulton who is the author of the tutorial

#import "AppDelegate.h"
#import "DSNetworking.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    // Override point for customization after application launch.
//    self.window.backgroundColor = [UIColor whiteColor];
//    [self.window makeKeyAndVisible];
    

   
    [self setAppearance];
    
                               
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textSizeChangedWithNotification:) name:UIContentSizeCategoryDidChangeNotification object:nil] ;
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    
  
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    

}

-(void)setAppearance {
    
    // tabBar appearance
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor colorWithRed:65.0/255 green:127.0/255 blue:6.0/255 alpha:1.0]];
    
    
      // navbar appearance
    NSDictionary *navBarTitleTextAttr = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    [[UINavigationBar appearance] setTitleTextAttributes:navBarTitleTextAttr];
    
    
    // barbutton appearance
    NSDictionary *barButtonItemTextAttr = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName: [UIColor colorWithRed:65.0/255 green:127.0/255  blue:6.0/255  alpha:1.0]};
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:barButtonItemTextAttr forState:UIControlStateNormal];

    
    
}

-(void)textSizeChangedWithNotification: (NSNotification *) notification {
    
    [self setAppearance];
    
}

@end
