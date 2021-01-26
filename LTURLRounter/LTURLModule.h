//
//  LTURLModule.h
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LTURLRounterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTURLModule : NSObject <LTURLModuleProtocol>

@property (nonatomic, copy, readonly) NSString *moduleName;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, LTURLModule *> *subModules;
@property (nonatomic, weak, readonly, nullable) LTURLModule *parentModule;

- (instancetype)initWithModuleName:(NSString *)moduleName
                      parentModule:(nullable LTURLModule *)parentModule;

/// @param module 根据模块进行注册
- (void)registerModule:(LTURLModule *)module;

/// @param moduleName 根据模块名称进行注销，注销后的模块不会再进行逻辑处理
- (void)unregisterModule:(NSString *)moduleName;

#pragma mark - Quik Use

/// 如果不想子类化，可以设置这个block来实现返回
@property(nonatomic, copy, nullable) BOOL (^canHandleURLBlock)(NSURL *url);
/// 如果不想子类化，可以设置这个block来实现返回
@property(nonatomic, copy, nullable) void (^handleURLBlock)(NSURL *url);

#pragma mark - 子类化处理

/// 当前模块是否解析这个URL
/// 当前模块能处理返回`YES`，否则返回`NO`
/// @param url 解析的URL
- (BOOL)canHandleURL:(NSURL *)url;

/// 处理这个URL，如果当前模块解析不了，直接返回
/// @param url 解析的URL
- (void)handleURL:(NSURL *)url;

/// 当前模块链是否解析这个URL，如果当前模块解析不了，会一层一层找自己的父模块，直到能解析或者父模块为空
/// 当前模块能处理或者父类模块有一个能处理返回YES，否则返回NO
/// @param url 解析的URL
- (BOOL)moduleChainCanHandleURL:(NSURL *)url;

/// 模块链处理这个URL这个URL，如果当前模块处理不了，直到找到能处理的模块去处理，如果没有就丢弃
/// @param url 解析的URL
- (void)moduleChainHandleURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
