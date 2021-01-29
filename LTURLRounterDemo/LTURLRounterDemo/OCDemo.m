//
//  OCDemo.m
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/29.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import "OCDemo.h"
#import "LTURLRounterDemo-Swift.h"

@implementation OCDemo

+ (void)testRounter {
    [self testSwiftRounter];
}

+ (void)testSwiftRounter {
    {
        [LTURLFlatRounter.sharedInstance registeModulesWithPathComponents:@[@"hotel", @"detail"] handleURLBlock:^(NSURL * _Nonnull url) {
            NSLog(@"跳转到酒店详情页");
        }];
        [LTURLFlatRounter.sharedInstance registeModulesWithPathComponents:@[@"hotel"] handleURLBlock:^(NSURL * _Nonnull url) {
            NSLog(@"跳转到酒店垂直页");
        }];
        
        [LTURLFlatRounter.sharedInstance handleWithUrl:[NSURL URLWithString:@"https://www.klook.com/hotel/1234/detail"]];
        [LTURLFlatRounter.sharedInstance handleWithUrl:[NSURL URLWithString:@"https://www.klook.com/hotel/1234/detail1"]];
    }
    
    {
        NSURL *url = [NSURL URLWithString:@"https://www.klook.com/hotel/1234/detail"];
        
        [LTURLRounter.sharedInstance registeWithSubModule:[self URLHandler]];
        id<LTURLModuleProtocol> bestModule = [LTURLRounter.sharedInstance bestModuleForUrl:url];
        //[bestModule handleURL:url];
        bestModule.moduleChainHandleBlock(url);
    }
}

+ (LTURLModule *)URLHandler {
    LTURLModule *hotel = [[LTURLModule alloc] initWithName:@"hotel" parentModule:nil];
    
    // 注册子模块
    {
        LTURLModule *detail = [[LTURLModule alloc] initWithName:@"detail" parentModule:hotel];
        detail.canHandleURLBlock = ^BOOL(NSURL * _Nonnull url) {
            return YES;
        };
        detail.handleURLBlock = ^(NSURL * _Nonnull url) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // do something
                NSLog(@"跳转到酒店详情页");
            });
        };
        [hotel registeWithSubModule:detail];
    }

    return hotel;
}

@end
