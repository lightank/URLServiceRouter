//
//  LTURLFlatRounter.m
//  LTURLRounterDemo
//
//  Created by huanyu.li on 2021/1/26.
//  Copyright © 2021 huanyu.li. All rights reserved.
//

#import "LTURLFlatRounter.h"

@interface LTURLFlatRounter ()

@property (nonatomic, copy) NSMutableDictionary<NSString *, LTURLModule *> *subModules;

@end

@implementation LTURLFlatRounter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static LTURLFlatRounter *instance = nil;
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

- (void)registeModuleWithPathComponents:(NSArray<NSString *> *)pathComponents
                         handleURLBlock:(void (^)(NSURL *url))handleURLBlock {
    if (pathComponents.count == 0) {
        return;
    }
    
    LTURLModule *currentModule = nil;
    for (NSString *pathComponent in pathComponents) {
        NSAssert(pathComponent.length > 0, @"注册的模块名称不能为空");
        if (!currentModule) {
            LTURLModule *subModule = _subModules[pathComponent];
            if (!subModule) {
                subModule = [[LTURLModule alloc] initWithName:pathComponent parentModule:nil];
                [self registeModule:subModule];
            }
            currentModule = subModule;
        } else {
            LTURLModule *subModule = currentModule.subModules[pathComponent];
            if (!subModule) {
                subModule = [[LTURLModule alloc] initWithName:pathComponent parentModule:currentModule];
                [currentModule registeWithSubModule:subModule];
            }
            currentModule = subModule;
        }
        
        if (pathComponent == pathComponents.lastObject) {
            NSAssert(!currentModule.handleURLBlock, @"模块:%@ 已经被注册过了,请检测", pathComponent);
            currentModule.canHandleURLBlock = ^BOOL(NSURL * _Nonnull url) {
                return YES;
            };
            
            currentModule.handleURLBlock = ^(NSURL * _Nonnull url) {
                if (handleURLBlock) {
                    handleURLBlock(url);
                }
            };
        }
    }
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
- (nullable LTURLModule *)bestModuleForUrl:(NSURL *)url {
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

- (void)handleWithUrl:(NSURL *)url {
    LTURLModule *bestModule = [self bestModuleForUrl:url];
    if (bestModule && [bestModule canModuleChainHandleWithUrl:url]) {
        [bestModule moduleChainHandleWithUrl:url];
    }
}

@end
