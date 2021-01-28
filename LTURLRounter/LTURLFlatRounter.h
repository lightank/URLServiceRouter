//
//  LTURLFlatRounter.h
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/26.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LTURLModule.h"
#import "LTURLRounterDemo-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTURLFlatRounter : NSObject <LTURLRounterProtocol>

@property (class, nonatomic, strong, readonly) LTURLFlatRounter *sharedInstance;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, LTURLModule *> *subModules;

- (void)registeModuleWithPathComponents:(NSArray<NSString *> *)pathComponents
                         handleURLBlock:(void (^)(NSURL *url))handleURLBlock;
- (void)unregisteModuleWithName:(NSString *)moduleName;

/// 找到最适合处理这个url的模块，如果没有就返回nil
/// @param url url
- (nullable LTURLModule *)bestModuleForUrl:(NSURL *)url;

/// 处理url
/// @param url url
- (void)handleWithUrl:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
