//
//  LTURLModule.m
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import "LTURLModule.h"

@interface LTURLModule ()

@property (nonatomic, copy) NSString *moduleName;
@property (nonatomic, strong) NSMutableDictionary<NSString *, LTURLModule *> *subModules;

@end

@implementation LTURLModule

- (instancetype)initWithModuleName:(NSString *)name parentModule:(nullable LTURLModule *)parentModule {
    NSAssert(name.length > 0, @"注册的模块名字不能为空,请检测");
    
    if (self = [self init]) {
        _moduleName = [name copy];
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

- (void)registerModule:(LTURLModule *)module {
    if (module.moduleName.length > 0) {
        if (_subModules[module.moduleName]) {
            NSAssert(NO, @"注册的模块重复了,请检测");
        } else {
            _subModules[module.moduleName] = module;
        }
    }
}

- (void)unregisterModule:(NSString *)moduleName
{
    if (moduleName.length > 0) {
        _subModules[moduleName] = nil;
    } else {
        NSAssert(NO, @"这个需要取消注册的模块尚未注册或已经被移除,请检测");
    }
}

- (BOOL)canHandleURL:(NSURL *)url
{
    if (self.canHandleURLBlock) {
        return self.canHandleURLBlock(url);
    }
    
    return NO;
}

- (BOOL)moduleChainCanHandleURL:(NSURL *)url
{
    BOOL canHandle = [self canHandleURL:url];
    if (!canHandle) {
        LTURLModule *parentHander = self.parentModule;
        do {
            canHandle = [parentHander canHandleURL:url];
            if (canHandle) {
                break;
            }
        } while (parentHander);
    }
    
    return canHandle;
}

- (void)handleURL:(NSURL *)url
{
    if (![self canHandleURL:url]) {
        return;
    }
    
    if (self.handleURLBlock) {
        self.handleURLBlock(url);
    }
}

- (void)moduleChainHandleURL:(NSURL *)url
{
    if (![self moduleChainCanHandleURL:url]) {
        return;
    }
    
    if ([self canHandleURL:url]) {
        [self handleURL:url];
    } else {
        if (self.parentModule) {
            [self.parentModule moduleChainHandleURL:url];
        }
    }
}

@end
