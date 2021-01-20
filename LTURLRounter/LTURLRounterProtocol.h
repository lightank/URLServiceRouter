//
//  LTURLRounterProtocol.h
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#ifndef LTURLRounterProtocol_h
#define LTURLRounterProtocol_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@protocol LTURLModuleProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol LTURLRounterProtocol <NSObject>

@property (nonatomic, strong, readonly) NSDictionary<NSString *, id<LTURLModuleProtocol>> *modules;

- (void)registerModule:(id<LTURLModuleProtocol>)module;
- (void)unregisterModuleWithName:(NSString *)moduleName;

/// 找到最适合处理这个url的模块，如果没有就返回nil
/// @param url url
- (nullable id<LTURLModuleProtocol>)bestModuleForURL:(NSURL *)url;

/// 处理url
/// @param url url
- (void)handlerURL:(NSURL *)url;

@end

@protocol LTURLModuleProtocol <NSObject>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id<LTURLModuleProtocol>> *subModules;
@property (nonatomic, strong, nullable) id<LTURLModuleProtocol> parentModule;

- (void)registerModule:(id<LTURLModuleProtocol>)module;
- (void)unregisterModuleWithName:(NSString *)moduleName;

/// 当前模块是否解析这个URL
/// @param url 解析的URL
- (BOOL)canHandleURL:(NSURL *)url;
/// 当前模块链是否解析这个URL，如果当前模块解析不了，会一层一层找自己的父模块，直到能解析或者父模块为空
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

#endif /* LTURLRounterProtocol_h */
