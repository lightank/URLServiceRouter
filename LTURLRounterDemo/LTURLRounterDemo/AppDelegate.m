//
//  AppDelegate.m
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import "AppDelegate.h"
#import "LTURLRounter.h"
#import "LTURLFlatRounter.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self testURLRounter];
    [self testURLFlatRounter];
    
    return YES;
}

- (void)testURLFlatRounter
{
    [LTURLFlatRounter.sharedInstance registerModuleWithPathComponents:@[@"hotel", @"detail"] handleURLBlock:^(NSURL * _Nonnull url) {
        NSLog(@"跳转到酒店详情页 - FlatRounter url:%@",url);
    }];
    [LTURLFlatRounter.sharedInstance registerModuleWithPathComponents:@[@"hotel"] handleURLBlock:^(NSURL * _Nonnull url) {
        NSLog(@"跳转到酒店垂直页 - FlatRounter url:%@",url);
    }];
    
    // 命中详情页
    [LTURLFlatRounter.sharedInstance handleURL:[NSURL URLWithString:@"https://www.klook.com/hotel/1234/detail"]];
    [LTURLFlatRounter.sharedInstance handleURL:[NSURL URLWithString:@"https://www.klook.com/hotel/detail"]];
    [LTURLFlatRounter.sharedInstance handleURL:[NSURL URLWithString:@"http://www.klook.com/hotel/detail"]];
    [LTURLFlatRounter.sharedInstance handleURL:[NSURL URLWithString:@"klook://www.klook.com/hotel/detail"]];
    [LTURLFlatRounter.sharedInstance handleURL:[NSURL URLWithString:@"https://www.klook.com/hotel/detail?key1=value1&key2=value2"]];
    [LTURLFlatRounter.sharedInstance handleURL:[NSURL URLWithString:@"https://www.klook.com/en_US/hotel/detail?key1=value1&key2=value2"]];
    [LTURLFlatRounter.sharedInstance handleURL:[NSURL URLWithString:@"https://www.klook.com/hotel/1234/detail/123"]];
    
    // 命中垂直页
    [LTURLFlatRounter.sharedInstance handleURL:[NSURL URLWithString:@"https://www.klook.com/hotel/1234/detail1"]];
    
    /*
    测试结果
    跳转到酒店详情页 - FlatRounter url:https://www.klook.com/hotel/1234/detail
    跳转到酒店详情页 - FlatRounter url:https://www.klook.com/hotel/detail
    跳转到酒店详情页 - FlatRounter url:http://www.klook.com/hotel/detail
    跳转到酒店详情页 - FlatRounter url:klook://www.klook.com/hotel/detail
    跳转到酒店详情页 - FlatRounter url:https://www.klook.com/hotel/detail?key1=value1&key2=value2
    跳转到酒店详情页 - FlatRounter url:https://www.klook.com/en_US/hotel/detail?key1=value1&key2=value2
    跳转到酒店详情页 - FlatRounter url:https://www.klook.com/hotel/1234/detail/123
    跳转到酒店垂直页 - FlatRounter url:https://www.klook.com/hotel/1234/detail1
     
    跳转到酒店详情页 - Rounter url:https://www.klook.com/hotel/1234/detail
    */
}

- (void)testURLRounter
{
    // 注册
    [LTURLRounter.sharedInstance registerModule:[self URLHandler]];
    NSURL *url = [NSURL URLWithString:@"https://www.klook.com/hotel/1234/detail"];
    LTURLModule *bestModule1 = [LTURLRounter.sharedInstance bestModuleForURL:url];
    // [bestModule1 handleURL:url];
    // 处理命中
    [bestModule1 moduleChainHandleURL:url];
    
    
    // 注销
    [LTURLRounter.sharedInstance unregisterModule:@"hotel"];
    LTURLModule *bestModule2 = [LTURLRounter.sharedInstance bestModuleForURL:url];
    // 此时 bestModule2 为nil
    [bestModule2 moduleChainHandleURL:url];
}

- (LTURLModule *)URLHandler
{
    // 构造主第一个模块
    LTURLModule *hotel = [[LTURLModule alloc] initWithModuleName:@"hotel" parentModule:nil];
    
    // 注册子模块
    {
        LTURLModule *detail = [[LTURLModule alloc] initWithModuleName:@"detail" parentModule:hotel];
        detail.canHandleURLBlock = ^BOOL(NSURL * _Nonnull url) {
            return YES;
        };
        detail.handleURLBlock = ^(NSURL * _Nonnull url) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // do something
                NSLog(@"跳转到酒店详情页 - Rounter url:%@",url);
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
