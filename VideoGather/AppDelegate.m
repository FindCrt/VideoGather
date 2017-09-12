//
//  AppDelegate.m
//  VideoGather
//
//  Created by shiwei on 17/8/31.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "AppDelegate.h"
#import "TFMenuViewController.h"
#import "TFBaseNavigationViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    TFMenuViewController *menuVC = [[TFMenuViewController alloc] init];
    self.window.rootViewController = [[TFBaseNavigationViewController alloc] initWithRootViewController:menuVC];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
