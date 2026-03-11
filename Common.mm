//
//  Common.mm
//
//
//  Created by Le Tien Dat on 3/4/26.
//

#include "Common.h"

NS_ASSUME_NONNULL_BEGIN

#define UD [NSUserDefaults standardUserDefaults]

@implementation Common

const char *frameworkName = NULL;
Common *common = [Common new];

- (void)setFrameworkName:(const char *)name_ {
  frameworkName = name_;
}
- (const char *)getFrameworkName {
  return frameworkName;
}

- (UIWindow *)getKeyWindow {
  if (@available(iOS 13.0, *)) {
    for (UIWindowScene *scene in [UIApplication sharedApplication]
             .connectedScenes) {
      if (scene.activationState == UISceneActivationStateForegroundActive) {
        for (UIWindow *window in scene.windows) {
          if (window.isKeyWindow) {
            return window;
          }
        }
      }
    }
  } else {
    return [UIApplication sharedApplication].keyWindow;
  }

  return nil;
}

- (UIViewController *)getRootViewController {
  UIWindow *keyWindow = [self getKeyWindow];
  if (!keyWindow) {
    return nil;
  }
  return [self getKeyWindow].rootViewController;
}

- (UIViewController *)getTopViewController {
  UIViewController *topController = [self getKeyWindow].rootViewController;
  if (!topController) {
    return nil;
  }

  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }

  if ([topController isKindOfClass:[UINavigationController class]]) {
    return ((UINavigationController *)topController).topViewController;
  } else if ([topController isKindOfClass:[UITabBarController class]]) {
    return ((UITabBarController *)topController).selectedViewController;
  }

  return topController;
}

- (void)setInt:(int)value forKey:(NSString *)key {
  [UD setInteger:value forKey:key];
  [UD synchronize];
}

- (int)integerForKey:(NSString *)key defaultValue:(int)defaultValue {
  if ([UD objectForKey:key]) {
    return (int)[UD integerForKey:key];
  }
  return defaultValue;
}

- (void)setBool:(bool)value forKey:(NSString *)key {
  [UD setBool:value forKey:key];
  [UD synchronize];
}

- (bool)boolForKey:(NSString *)key defaultValue:(bool)defaultValue {
  if ([UD objectForKey:key]) {
    return [UD boolForKey:key];
  }
  return defaultValue;
}

@end

NS_ASSUME_NONNULL_END
