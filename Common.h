//
//  Common.h
//  
//
//  Created by Le Tien Dat on 3/4/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Common : NSObject

-(void)setFrameworkName:(const char *)name_;
-(const char *)getFrameworkName;

-(UIWindow *)getKeyWindow;
-(UIViewController *)getRootViewController;
-(UIViewController *)getTopViewController;

@end

extern Common *common;

NS_ASSUME_NONNULL_END
