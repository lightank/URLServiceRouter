//
//  LTURLModule.m
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import "LTURLModule.h"

@interface LTURLModule ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSMutableDictionary<NSString *, LTURLModule *> *subModules;

@end

@implementation LTURLModule

- (instancetype)initWithName:(NSString *)name parentModule:(nullable LTURLModule *)parentModule {
    NSAssert(name.length > 0, @"注册的模块名字不能为空,请检测");
    
    if (self = [self init]) {
        _name = [name copy];
        _parentModule = parentModule;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _subModules = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registeWithSubModule:(LTURLModule *)subModule {
    NSAssert(subModule.name.length > 0, @"注册的模块名字不能为空,请检测");
    
    if (subModule.name.length > 0) {
        if (_subModules[subModule.name]) {
            NSAssert(NO, @"模块:%@ 中的子模块:%@ 已经被注册过了,请检测", self.name, subModule.name);
        } else {
            _subModules[subModule.name] = subModule;
        }
    }
}

- (void)unregisteWithSubModuleName:(NSString * _Nonnull)subModuleName {
    NSAssert(subModuleName.length > 0, @"取消注册的模块名字不能为空,请检测");

    if (subModuleName.length > 0) {
        _subModules[subModuleName] = nil;
    } else {
        NSAssert(NO, @"这个需要取消注册的模块:%@,尚未注册或已经被移除,请检测", subModuleName);
    }
}

- (BOOL)canHandleWithUrl:(NSURL * _Nonnull)url { 
    if (self.canHandleURLBlock) {
        return self.canHandleURLBlock(url);
    }
    return NO;
}

- (BOOL)canModuleChainHandleWithUrl:(NSURL * _Nonnull)url { 
    BOOL canHandle = [self canHandleWithUrl:url];
    if (!canHandle) {
        LTURLModule *parentHander = self.parentModule;
        do {
            canHandle = [parentHander canHandleWithUrl:url];
            if (canHandle) {
                break;
            }
        } while (parentHander);
    }
    return canHandle;
}

- (void)handleWithUrl:(NSURL * _Nonnull)url { 
    if (![self canHandleWithUrl:url]) {
        return;
    }
    
    if (self.handleURLBlock) {
        self.handleURLBlock(url);
    }
}

- (void)moduleChainHandleWithUrl:(NSURL * _Nonnull)url { 
    if (![self canModuleChainHandleWithUrl:url]) {
        return;
    }
    
    if ([self canHandleWithUrl:url]) {
        [self handleWithUrl:url];
    } else {
        if (self.parentModule) {
            [self.parentModule moduleChainHandleWithUrl:url];
        }
    }
}


@end
