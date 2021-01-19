//
//  LTURLRounter.m
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/19.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import "LTURLRounter.h"

@interface LTURLRounter ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, LTURLModule *> *modules;

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
        _modules = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerModule:(LTURLModule *)module {
    if (module.name.length > 0) {
        if (_modules[module.name]) {
            NSAssert(NO, @"注册的模块重复了,请检测");
        } else {
            _modules[module.name] = module;
        }
    }
}

- (void)unregisterModuleWithName:(NSString *)moduleName {
    if (moduleName.length > 0) {
        _modules[moduleName] = nil;
    } else {
        NSLog(@"这个需要取消注册的模块尚未注册或已经被移除,请检测");
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
        if (bestModule == nil) {
            LTURLModule *subModule = _modules[pathComponent];
            if (subModule) {
                bestModule = subModule;
            }
        } else {
            LTURLModule *subModule = bestModule.subModules[pathComponent];
            if (subModule) {
                bestModule = subModule;
            }
        }
    }
    return bestModule;
}

- (void)handlerURL:(NSURL *)url {
    LTURLModule *bestModule = [self bestModuleForURL:url];
    if (bestModule && [bestModule canModuleChainHandleURL:url]) {
        [bestModule moduleChainHandleURL:url];
    }
}

@end
