//
//  LTURLModule.h
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LTURLRounterDemo-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTURLModule : NSObject <LTURLModuleProtocol>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, LTURLModule *> *subModules;
@property (nonatomic, weak, nullable, readonly) LTURLModule *parentModule;

- (instancetype)initWithName:(NSString *)name parentModule:(nullable LTURLModule *)parentModule;
- (void)registeWithSubModule:(LTURLModule *)subModule;
- (void)unregisteWithSubModuleName:(NSString * _Nonnull)subModuleName;

/// 如果不想子类化，可以设置这个block来实现返回
@property(nonatomic, copy, nullable) BOOL (^canHandleURLBlock)(NSURL *url);
/// 如果不想子类化，可以设置这个block来实现具体处理
@property(nonatomic, copy, nullable) void (^handleURLBlock)(NSURL *url);

- (BOOL)canHandleWithUrl:(NSURL * _Nonnull)url;
- (BOOL)canModuleChainHandleWithUrl:(NSURL * _Nonnull)url;
- (void)handleWithUrl:(NSURL * _Nonnull)url;
- (void)moduleChainHandleWithUrl:(NSURL * _Nonnull)url;

@end

NS_ASSUME_NONNULL_END
