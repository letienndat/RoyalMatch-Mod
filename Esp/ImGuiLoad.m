//
//  ImGuiLoad.m
//  ImGuiTest
//
//  Created by yiming on 2021/6/2.
//

#import "ImGuiLoad.h"
#import "../Common.h"
#import "ImGuiDrawView.h"
#import "JHPP.h"

@interface ImGuiLoad ()
@property(nonatomic, strong) ImGuiDrawView *imGUI;
@end

static UIWindow *mainWindow;

@implementation ImGuiLoad

static ImGuiLoad *extraInfo;

+ (void)load {
  [super load];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   mainWindow = [common getKeyWindow];
                   extraInfo = [ImGuiLoad new];
                   [extraInfo initTapGes];
                   [extraInfo initTapGesHide];
                   [extraInfo show];
                 });
}

- (void)initTapGes {
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
  tap.numberOfTapsRequired = 2;    // 点击次数
  tap.numberOfTouchesRequired = 3; // 手指数
  [[JHPP currentViewController].view addGestureRecognizer:tap];
  [tap addTarget:self action:@selector(show)];
}

- (void)initTapGesHide {
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
  tap.numberOfTapsRequired = 2;    // 点击次数
  tap.numberOfTouchesRequired = 2; // 手指数
  [[JHPP currentViewController].view addGestureRecognizer:tap];
  [tap addTarget:self action:@selector(hide)];
}

- (void)show {
  if (!_imGUI) {
    ImGuiDrawView *vc = [ImGuiDrawView new];
    _imGUI = vc;
  }

  [ImGuiDrawView showChange:YES];
  if (!_imGUI.view.superview) {
    UIViewController *topVC = [common getTopViewController];
    [topVC.view addSubview:_imGUI.view];
  }
  _imGUI.view.hidden = NO;
}

- (void)hide {
  if (_imGUI) {
    [ImGuiDrawView showChange:NO];
    _imGUI.view.hidden = YES;
  }
}

@end
