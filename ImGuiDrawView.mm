#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"
#import "Macros.h"
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
  [self hook];
}

- (void)hook {
  LOG(@"========= Start hooking =========");

  // int32_t __fastcall Royal_Infrastructure_Services_Storage_Tables_UserKeyValue__GetInt(
  //     System_String_o * key, int32_t defaultValue, const MethodInfo *method)
  HOOK_V2(ENCRYPTOFFSET("0x006F35E8"), userKeyValue_SetInt, _userKeyValue_SetInt);
  HOOK_V2(ENCRYPTOFFSET("0x006F369C"), userKeyValue_SetLong, _userKeyValue_SetLong);
  HOOK_V2(ENCRYPTOFFSET("0x006E4DF0"), userKeyValue_SetIntWithDB, _userKeyValue_SetIntWithDB);
  HOOK_V2(ENCRYPTOFFSET("0x006E501C"), userKeyValue_SetLongWithDB, _userKeyValue_SetLongWithDB);
  HOOK_V2(ENCRYPTOFFSET("0x006F3618"), userKeyValue_GetInt, _userKeyValue_GetInt);
  HOOK_V2(ENCRYPTOFFSET("0x006F36CC"), userKeyValue_GetLong, _userKeyValue_GetLong);
  HOOK_V2(ENCRYPTOFFSET("0x006E4EFC"), userKeyValue_GetIntWithDB, _userKeyValue_GetIntWithDB);
  HOOK_V2(ENCRYPTOFFSET("0x006E5128"), userKeyValue_GetLongWithDB, _userKeyValue_GetLongWithDB);

  LOG(@"========= Hooking done =========");
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
    CGFloat height = kHeight * (isIpad ? 0.6 : 0.7);
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

      ImGui::Checkbox("Coins", &isActiveCoin);
      ImGui::SameLine();
      ImGui::SliderInt("##_Coins", &coins, 0, 999999);
      ImGui::Checkbox("Level", &isActiveLevel);
      ImGui::SameLine();
      ImGui::SliderInt("##_Level", &level, 1, 13201);
      ImGui::Checkbox("Stars", &isActiveStar);
      ImGui::SameLine();
      ImGui::SliderInt("##_Stars", &stars, 0, 99999);
      ImGui::Checkbox("Chest", &isActiveChest);
      ImGui::SameLine();
      ImGui::SliderInt("##_Chest", &chest, 0, 1000);

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
