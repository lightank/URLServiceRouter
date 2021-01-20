//
//  AppDelegate.m
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import "AppDelegate.h"
#import "LTURLRounter.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
    [self testURLRounter];
    
    return YES;
}

- (void)testURLRounter {
    [LTURLRounter.sharedInstance registerModule:[self URLHandler]];
    NSURL *url = [NSURL URLWithString:@"https://www.klook.com/hotel/1234/detail"];
    LTURLModule *bestModule = [LTURLRounter.sharedInstance bestModuleForURL:url];
    //[bestModule handleURL:url];
    [bestModule moduleChainHandleURL:url];
    NSLog(@"");
}

- (LTURLModule *)URLHandler {
    LTURLModule *hotel = [[LTURLModule alloc] initWithName:@"hotel"];
    
    // 注册子模块
    {
        LTURLModule *detail = [[LTURLModule alloc] initWithName:@"detail"];
        detail.canHandleURLBlock = ^BOOL(NSURL * _Nonnull url) {
            return YES;
        };
        detail.handleURLBlock = ^(NSURL * _Nonnull url) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // do something
                NSLog(@"跳转到酒店详情页");
            });
        };
        [hotel registerModule:detail];
    }

    return hotel;
}



#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
