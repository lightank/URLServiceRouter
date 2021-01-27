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
@property (nonatomic, strong) NSMutableDictionary<NSString *, LTURLModule *> *subModules;

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

- (void)registeModule:(LTURLModule *)module {
    NSAssert(module.name.length > 0, @"注册的模块名字不能为空,请检测");
    
    if (module.name.length > 0) {
        if (_subModules[module.name]) {
            NSAssert(NO, @"模块:%@ 中的子模块:%@ 已经被注册过了,请检测", self.name, module.name);
        } else {
            _subModules[module.name] = module;
        }
    }
}

- (void)unregisteModuleWithName:(NSString *)moduleName {
    NSAssert(moduleName.length > 0, @"取消注册的模块名字不能为空,请检测");

    if (moduleName.length > 0) {
        _subModules[moduleName] = nil;
    } else {
        NSAssert(NO, @"这个需要取消注册的模块:%@,尚未注册或已经被移除,请检测", moduleName);
    }
}

- (BOOL)canHandleURL:(NSURL *)url {
    if (self.canHandleURLBlock) {
        return self.canHandleURLBlock(url);
    }
    return NO;
}

- (BOOL)canModuleChainHandleURL:(NSURL *)url {
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

- (void)handleURL:(NSURL *)url {
    if (![self canHandleURL:url]) {
        return;
    }
    
    if (self.handleURLBlock) {
        self.handleURLBlock(url);
    }
}

- (void)moduleChainHandleURL:(NSURL *)url {
    if (![self canModuleChainHandleURL:url]) {
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
