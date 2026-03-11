#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"
#import "Macros.h"
#import "giovotinh/hook.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>

#define NAME_BINARY "Frameworks/UnityFramework.framework/UnityFramework"
#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale

@interface ImGuiDrawView () <MTKViewDelegate>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@end

@implementation ImGuiDrawView

static bool isShowMenu = true;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

  _device = MTLCreateSystemDefaultDevice();
  _commandQueue = [_device newCommandQueue];

  if (!self.device)
    abort();

  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  ImGuiIO &io = ImGui::GetIO();
  (void)io;

  ImGui::StyleColorsClassic();

  ImFont *font = io.Fonts->AddFontFromMemoryCompressedTTF(
      (void *)zzz_compressed_data, zzz_compressed_size, 60.0f, NULL,
      io.Fonts->GetGlyphRangesVietnamese());

  ImGui_ImplMetal_Init(_device);

  return self;
}

- (void)loadView {
  self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight)];
  [self setup];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.mtkView.device = self.device;
  self.mtkView.delegate = self;
  self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
  self.mtkView.backgroundColor = [UIColor colorWithRed:0
                                                 green:0
                                                  blue:0
                                                 alpha:0];
  self.mtkView.clipsToBounds = YES;
}

- (void)setup {
  [common setFrameworkName:NAME_BINARY];
  [self loadState];
  [self hook];
}

- (void)loadState {
  isActiveCoin = [common boolForKey:@"isActiveCoin" defaultValue:NO];
  coins = [common integerForKey:@"Coins" defaultValue:0];
  isActiveStar = [common boolForKey:@"isActiveStar" defaultValue:NO];
  stars = [common integerForKey:@"Stars" defaultValue:0];
}

- (void)hook {
  LOG(NSSENCRYPT("========= Start hooking ========="));

  HOOK_V2(
      ENCRYPTOFFSET("0x00464190"),
      Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge,
      _Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge);

  LOG(NSSENCRYPT("========= Hooking done ========="));
}

- (void)patch {
  // patchOffset(0x1000056c8, "08 00 80 52");
  // patchOffset(0x1000056ec, "16 00 80 52");
  // patchOffset(0x1000057c4, "08 00 80 52");
}

+ (void)showChange:(BOOL)open {
  isShowMenu = open;
}

- (MTKView *)mtkView {
  return (MTKView *)self.view;
}

#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event {
  UITouch *anyTouch = event.allTouches.anyObject;
  CGPoint touchLocation = [anyTouch locationInView:self.view];
  ImGuiIO &io = ImGui::GetIO();
  io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

  BOOL hasActiveTouch = NO;
  for (UITouch *touch in event.allTouches) {
    if (touch.phase != UITouchPhaseEnded &&
        touch.phase != UITouchPhaseCancelled) {
      hasActiveTouch = YES;
      break;
    }
  }
  io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches
               withEvent:(UIEvent *)event {
  [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [self updateIOWithTouchEvent:event];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
  // Resize view rotate the screen
  self.view.frame = CGRectMake(0, 0, kWidth, kHeight);

  ImGuiIO &io = ImGui::GetIO();
  io.DisplaySize.x = view.bounds.size.width;
  io.DisplaySize.y = view.bounds.size.height;

  CGFloat framebufferScale =
      view.window.screen.scale ?: UIScreen.mainScreen.scale;
  io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
  io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);

  id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

  if (isShowMenu == true) {
    [self.view setUserInteractionEnabled:YES];
  } else if (isShowMenu == false) {
    [self.view setUserInteractionEnabled:NO];
  }

  MTLRenderPassDescriptor *renderPassDescriptor =
      view.currentRenderPassDescriptor;
  if (renderPassDescriptor != nil) {
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder pushDebugGroup:@"ImGui"];

    ImGui_ImplMetal_NewFrame(renderPassDescriptor);
    ImGui::NewFrame();

    ImFont *font = ImGui::GetFont();
    font->Scale = 15.f / font->FontSize;

    bool isIpad = ([[UIDevice currentDevice] userInterfaceIdiom] ==
                   UIUserInterfaceIdiomPad);

    CGFloat width = kWidth * (isIpad ? 0.5 : 0.8);
    CGFloat height = kHeight * (isIpad ? 0.6 : 0.5);
    CGFloat x = (kWidth - width) / 2;
    CGFloat y = (kHeight - height) / 2;

    static float lastKnownWidth = 0;
    static float lastKnownHeight = 0;

    if (lastKnownWidth != kWidth || lastKnownHeight != kHeight) {
      ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Always);
      ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_Always);

      lastKnownWidth = kWidth;
      lastKnownHeight = kHeight;
    } else {
      ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Appearing);
      ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_Appearing);
    }

    if (isShowMenu) {
      ImGui::Begin("Royal Match Mod", &isShowMenu);
      ImGui::TextWrapped("Use 3 Fingers Click 3 Times Open Menu\n2 Finger Tap Screen 2 Times Hide Menu");
      ImGui::TextWrapped("Dùng 3 ngón chạm 2 lần để mở menu\n2 ngón chạm 2 lần để ẩn menu\n\n");

      ImGui::TextWrapped("Click on the type you want to mod + adjust the quantity you want to mod.\n"
                         "Then click Apply, the game will update automatically.");
      ImGui::TextWrapped("Chọn thể loại muốn mod + kéo thanh điều chỉnh số lượng muốn mod.\n"
                         "Sau đó bấm Áp dụng, trò chơi sẽ tự động cập nhật.\n\n");

      ImGui::Checkbox("Coins (Vàng)", &isActiveCoin);
      ImGui::SliderInt("##_Coins", &coins, 0, 999999);
      ImGui::Text("\n");
      ImGui::Checkbox("Stars", &isActiveStar);
      ImGui::SliderInt("##_Stars", &stars, 0, 9999);
      ImGui::Text("\n");

      if (ImGui::Button("Apply / Áp dụng")) {
        applyMod();
        [common setBool:isActiveCoin forKey:@"isActiveCoin"];
        [common setBool:isActiveStar forKey:@"isActiveStar"];
        if (isActiveCoin) {
          [common setInt:coins forKey:@"Coins"];
        }
        if (isActiveStar) {
          [common setInt:stars forKey:@"Stars"];
        }
      }

      ImGui::TextWrapped("\nFPS: %.1f", ImGui::GetIO().Framerate);

      ImGui::End();
    }

    [self patch];

    ImDrawList *draw_list = ImGui::GetBackgroundDrawList();

    ImGui::Render();
    ImDrawData *draw_data = ImGui::GetDrawData();
    ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);

    [renderEncoder popDebugGroup];
    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:view.currentDrawable];
  }

  [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
}

@end
