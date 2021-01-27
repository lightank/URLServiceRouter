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

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, LTURLModule *> *subModules;
@property (nonatomic, weak, nullable, readonly) LTURLModule *parentModule;

- (instancetype)initWithName:(NSString *)name parentModule:(nullable LTURLModule *)parentModule;
- (void)registeModule:(LTURLModule *)module;
- (void)unregisteModuleWithName:(NSString *)moduleName;

/// 如果不想子类化，可以设置这个block来实现返回
@property(nonatomic, copy, nullable) BOOL (^canHandleURLBlock)(NSURL *url);
/// 如果不想子类化，可以设置这个block来实现返回
@property(nonatomic, copy, nullable) void (^handleURLBlock)(NSURL *url);

/// 当前模块是否可以解析这个URL
/// @param url 解析的URL
- (BOOL)canHandleURL:(NSURL *)url;
/// 当前模块链是否可以解析这个URL，如果当前模块解析不了，会一层一层找自己的父模块，直到能解析或者父模块为空
/// @param url 解析的URL
- (BOOL)canModuleChainHandleURL:(NSURL *)url;
/// 处理这个URL，如果当前模块解析不了，直接返回
/// @param url 解析的URL
- (void)handleURL:(NSURL *)url;
/// 模块链处理这个URL这个URL，如果当前模块处理不了，直到找到能处理的模块去处理，如果没有就丢弃
/// @param url 解析的URL
- (void)moduleChainHandleURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
