//
//  LTURLRounter.m
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import "LTURLRounter.h"

@interface LTURLRounter ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, LTURLModule *> *subModules;

@end

@implementation LTURLRounter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LTURLRounter *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
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
            NSAssert(NO, @"路由中心的模块:%@ 已经被注册过了,请检测", module.name);
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

/// 找到最适合处理这个url的模块，如果没有就返回nil
/// @param url url
- (nullable LTURLModule *)bestModuleForURL:(NSURL *)url {
    if (url.absoluteString.length == 0 || url.pathComponents.count == 0) {
        return nil;
    }
    
    // 找到合适模块
    NSArray<NSString *> *pathComponents = url.pathComponents;
    LTURLModule *bestModule = nil;
    for (NSString *pathComponent in pathComponents) {
        LTURLModule *subModule = nil;
        if (bestModule == nil) {
            subModule = _subModules[pathComponent];
        } else {
            subModule = bestModule.subModules[pathComponent];
        }
        
        if (subModule) {
            bestModule = subModule;
        }
    }
    return bestModule;
}

- (void)handleURL:(NSURL *)url {
    LTURLModule *bestModule = [self bestModuleForURL:url];
    if (bestModule && [bestModule canModuleChainHandleURL:url]) {
        [bestModule moduleChainHandleURL:url];
    }
}

@end
