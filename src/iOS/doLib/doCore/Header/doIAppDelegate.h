//
//  doIAppDelegate.h
//  DoCore
//
//  Created by 刘吟 on 15/4/9.
//  Copyright (c) 2015年 DongXian. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol doIAppDelegate <NSObject>
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)applicationWillResignActive:(UIApplication *)application ;
- (void)applicationDidEnterBackground:(UIApplication *)application ;
- (void)applicationWillEnterForeground:(UIApplication *)application ;
- (void)applicationDidBecomeActive:(UIApplication *)application ;
- (void)applicationWillTerminate:(UIApplication *)application ;
@end
