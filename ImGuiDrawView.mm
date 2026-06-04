#import "Esp/ImGuiDrawView.h"
#import "GioVoTinh/hook.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/imgui_internal.h"
#import "IMGUI/stb_image.h"
#import "IMGUI/zzz.h"
#import "Macros.h"
#import "Resources/Resources.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>

#define NAME_BINARY "Frameworks/UnityFramework.framework/UnityFramework"
#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale
#define kFloatButtonWidth 50
#define kFloatButtonHeight 50
#define kPaddingVertical 35
#define kPaddingHorizontal 10

enum : int {
    ImGuiIOSKey_Backspace = 8,
    ImGuiIOSKey_Enter = 13,
    ImGuiIOSKey_Escape = 27,
    ImGuiIOSKey_Tab = 9,
};

@interface ImGuiDrawView () <MTKViewDelegate, UITextFieldDelegate, UIKeyInput>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, weak) UIView *floatButtonHostView;
@property(nonatomic, strong) UIImageView *floatButtonImageView;
@property(nonatomic, assign) BOOL keyboardDismissedByUser;
@property(nonatomic, assign) BOOL hookingDone;
@end

static bool supportRotateScreen = true;
static bool isShowMenu = false;

@implementation ImGuiDrawView

+ (instancetype)sharedInstance {
    static ImGuiDrawView *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

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

    io.KeyMap[ImGuiKey_Tab] = ImGuiIOSKey_Tab;
    io.KeyMap[ImGuiKey_Enter] = ImGuiIOSKey_Enter;
    io.KeyMap[ImGuiKey_KeyPadEnter] = ImGuiIOSKey_Enter;
    io.KeyMap[ImGuiKey_Escape] = ImGuiIOSKey_Escape;
    io.KeyMap[ImGuiKey_Backspace] = ImGuiIOSKey_Backspace;

    ImGui::StyleColorsClassic();

    ImFontConfig config;
    ImFontConfig icons_config;
    config.FontDataOwnedByAtlas = false;
    icons_config.MergeMode = true;
    icons_config.PixelSnapH = true;
    icons_config.OversampleH = 2;
    icons_config.OversampleV = 2;

    io.Fonts->AddFontFromMemoryCompressedTTF(
        (void *)zzz_compressed_data, zzz_compressed_size, 60.0f, NULL,
        io.Fonts->GetGlyphRangesVietnamese());

    ImGui_ImplMetal_Init(_device);

    return self;
}

- (void)loadView {
    self.view =
        [[MTKView alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight)];
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

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(handleKeyboardWillHide:)
               name:UIKeyboardWillHideNotification
             object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup {
    [common setFrameworkName:NAME_BINARY];
    [self initData];
    [self loadSetting];

    // Try resolve il2cpp to load symbol il2cpp_*
    // Run on background thread
    static dispatch_once_t once;
    timer_background(0.5) {
        dispatch_once(&once, ^{
          if ([self handleIl2cpp]) {
              timer_background(0.1) {
                  [self loadSymbolAutoUpdate];
                  timer(1) { [self hook]; });
              });
              return;
          }

          LOG(@"%@", NSSENCRYPT("Second: Try IL2CppResolver"));
          NSString *dirString = binaryPath(@NAME_BINARY);
          if (IL2CPP_Resolver::Initialize(true, WAIT_TIME_SEC,
                                          [dirString UTF8String])) {
              LOG(@"%@", NSSENCRYPT("Second: IL2CppResolver success!"));
              [self assignPointerIl2cpp];
              timer_background(0.1) {
                  [self loadSymbolAutoUpdate];
                  timer(1) { [self hook]; });
              });
              return;
          }

          LOG(@"%@", NSSENCRYPT("All resolver paths failed"));
          LOG(@"%@", NSSENCRYPT("Use hard offset"));

          timer_background(0.1) {
              [self loadSymbolHardOffset];
              timer(1) { [self hook]; });
          });
        });
    });
}

- (void)initData {
    self.hookingDone = NO;
}

- (BOOL)handleIl2cpp {
    LOG(@"%@", NSSENCRYPT("First: Try il2cpp"));
    BOOL res = Il2CppAttach();
    LOG(@"%@", res ? NSSENCRYPT("First: il2cpp success!")
                   : NSSENCRYPT("First: il2cpp fail!"));

    return res;
}

- (void)assignPointerIl2cpp {
    IL2CPP::il2cpp_assembly_get_image =
        reinterpret_cast<const void *(*)(const void *)>(
            IL2CPP_Resolver::Functions.m_AssembliesGetImage);
    IL2CPP::il2cpp_domain_get =
        reinterpret_cast<void *(*)()>(IL2CPP_Resolver::Functions.m_DomainGet);
    IL2CPP::il2cpp_domain_get_assemblies =
        reinterpret_cast<void **(*)(const void *, size_t *)>(
            IL2CPP_Resolver::Functions.m_DomainGetAssemblies);
    IL2CPP::il2cpp_image_get_name = reinterpret_cast<const char *(*)(void *)>(
        IL2CPP_Resolver::Functions.m_ImageGetName);
    IL2CPP::il2cpp_class_from_name =
        reinterpret_cast<void *(*)(const void *, const char *, const char *)>(
            IL2CPP_Resolver::Functions.m_ClassFromName);
    IL2CPP::il2cpp_class_get_method_from_name =
        reinterpret_cast<void *(*)(void *, const char *, int)>(
            IL2CPP_Resolver::Functions.m_ClassGetMethodFromName);
    IL2CPP::il2cpp_class_get_field_from_name =
        reinterpret_cast<void *(*)(void *, const char *)>(
            IL2CPP_Resolver::Functions.m_ClassGetFieldFromName);
    IL2CPP::il2cpp_field_get_offset = reinterpret_cast<size_t (*)(void *)>(
        IL2CPP_Resolver::Functions.m_ClassGetFieldOffset);
    IL2CPP::il2cpp_field_static_get_value =
        reinterpret_cast<void (*)(void *, void *)>(
            IL2CPP_Resolver::Functions.m_FieldStaticGetValue);
    IL2CPP::il2cpp_field_static_set_value =
        reinterpret_cast<void (*)(void *, void *)>(
            IL2CPP_Resolver::Functions.m_FieldStaticSetValue);

    // Additional IL2CPP function assignments
    IL2CPP::il2cpp_string_new = reinterpret_cast<void *(*)(const char *)>(
        IL2CPP_Resolver::Functions.m_StringNew);
    IL2CPP::il2cpp_string_new_utf16 =
        reinterpret_cast<void *(*)(const wchar_t *, int32_t)>(
            IL2CPP_Resolver::Functions.m_StringNewUTF16);
    IL2CPP::il2cpp_string_chars = reinterpret_cast<uint16_t *(*)(void *)>(
        IL2CPP_Resolver::Functions.m_StringChars);

    // v2
    IL2CPP::il2cpp_thread_get_name =
        reinterpret_cast<char *(*)(void *, uint32_t *)>(
            IL2CPP_Resolver::Functions.m_ThreadGetName);
    IL2CPP::il2cpp_thread_current = reinterpret_cast<void *(*)()>(
        IL2CPP_Resolver::Functions.m_ThreadCurrent);
    IL2CPP::il2cpp_thread_attach = reinterpret_cast<void *(*)(void *)>(
        IL2CPP_Resolver::Functions.m_ThreadAttach);
    IL2CPP::il2cpp_thread_detach = reinterpret_cast<void (*)(void *)>(
        IL2CPP_Resolver::Functions.m_ThreadDetach);
    IL2CPP::il2cpp_runtime_invoke =
        reinterpret_cast<void *(*)(const void *, void *, void **, void **)>(
            IL2CPP_Resolver::Functions.m_RuntimeInvoke);
    IL2CPP::il2cpp_object_unbox = reinterpret_cast<void *(*)(void *)>(
        IL2CPP_Resolver::Functions.m_ObjectUnbox);
    IL2CPP::il2cpp_object_new = reinterpret_cast<void *(*)(const void *)>(
        IL2CPP_Resolver::Functions.m_pObjectNew);
    IL2CPP::il2cpp_gchandle_new = reinterpret_cast<uint32_t (*)(void *, bool)>(
        IL2CPP_Resolver::Functions.m_GchandleNew);
    IL2CPP::il2cpp_gchandle_free = reinterpret_cast<void (*)(uint32_t)>(
        IL2CPP_Resolver::Functions.m_GchandleFree);
}

- (void)loadSymbolAutoUpdate {
    Il2CppMethod methodAccessSystem(ENCRYPT("Assembly-CSharp.dll"));
    Il2CppField fieldAccessSystem(ENCRYPT("Assembly-CSharp.dll"));

    // ====================== FIELD OFFSETS ======================
    coinOffset = (uintptr_t)fieldAccessSystem
                     .getClass(oxorany("Royal.Player.Context.Data.Persistent"),
                               oxorany("UserInventory"))
                     .getField(oxorany("<Coins>k__BackingField"))
                     .getOffset();
    starOffset = (uintptr_t)fieldAccessSystem
                     .getClass(oxorany("Royal.Player.Context.Data.Persistent"),
                               oxorany("UserInventory"))
                     .getField(oxorany("<Stars>k__BackingField"))
                     .getOffset();
    moveOffset = (uintptr_t)fieldAccessSystem
                     .getClass(oxorany("Royal.Scenes.Game.Levels.Units"),
                               oxorany("MoveManager"))
                     .getField(oxorany("<LeftMoves>k__BackingField"))
                     .getOffset();

    // ====================== METHOD / STATIC OFFSETS ======================
    Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge_Offset =
        methodAccessSystem
            .getClass(
                oxorany("Royal.Scenes.Home.Ui.Sections.Home.InventoryPanel"),
                oxorany("LifeInfoView"))
            .getMethod(oxorany("ArrangeInboxBadge"), 1);
    Game_Levels_Units_MoveManager__SetMaxMoves_Offset =
        methodAccessSystem
            .getClass(oxorany("Royal.Scenes.Game.Levels.Units"),
                      oxorany("MoveManager"))
            .getMethod(oxorany("SetMaxMoves"), 1);
    Game_Levels_Units_MoveManager__SetMovesForStart_Offset =
        methodAccessSystem
            .getClass(oxorany("Royal.Scenes.Game.Levels.Units"),
                      oxorany("MoveManager"))
            .getMethod(oxorany("SetMovesForStart"), 3);

    // ====================== FUNCTION POINTERS ======================
    updateCoins = (void (*)(void *, int32_t, void *))getRealOffset(
        methodAccessSystem
            .getClass(oxorany("Royal.Player.Context.Data.Persistent"),
                      oxorany("UserInventory"))
            .getMethod(oxorany("UpdateCoins"), 1));
    spendCoins =
        (bool (*)(void *, Royal_Player_Context_Data_Session_SpendingData_o,
                  void *, int32_t, void *))
            getRealOffset(
                methodAccessSystem
                    .getClass(oxorany("Royal.Player.Context.Data.Persistent"),
                              oxorany("UserInventory"))
                    .getMethod(oxorany("SpendCoins"), 3));
    updateStars = (void (*)(void *, int32_t, void *))getRealOffset(
        methodAccessSystem
            .getClass(oxorany("Royal.Player.Context.Data.Persistent"),
                      oxorany("UserInventory"))
            .getMethod(oxorany("UpdateStars"), 1));
    triggerMoveChanged = (void (*)(void *, int32_t, void *))getRealOffset(
        methodAccessSystem
            .getClass(oxorany("Royal.Scenes.Game.Levels.Units"),
                      oxorany("MoveManager"))
            .getMethod(oxorany("TriggerMoveChanged"), 1));
}

- (void)loadSymbolHardOffset {
    // ====================== FIELD OFFSETS ======================
    coinOffset =
        ENCRYPTOFFSET("0x10"); // private int <Coins>k__BackingField; // 0x10
    starOffset =
        ENCRYPTOFFSET("0x14"); // private int <Stars>k__BackingField; // 0x14
    moveOffset = ENCRYPTOFFSET(
        "0x20"); // private int <LeftMoves>k__BackingField; // 0x20

    // ====================== METHOD / STATIC OFFSETS ======================
    Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge_Offset =
        (uintptr_t)ENCRYPTOFFSET("0x464190");
    Game_Levels_Units_MoveManager__SetMaxMoves_Offset =
        (uintptr_t)ENCRYPTOFFSET("0x4534E8");
    Game_Levels_Units_MoveManager__SetMovesForStart_Offset =
        (uintptr_t)ENCRYPTOFFSET("0x453524");

    // ====================== FUNCTION POINTERS ======================
    updateCoins = (void (*)(void *, int32_t, void *))getRealOffset(
        ENCRYPTOFFSET("0x6A05D4"));
    spendCoins = (bool (*)(
        void *, Royal_Player_Context_Data_Session_SpendingData_o, void *,
        int32_t, void *))getRealOffset(ENCRYPTOFFSET("0x6A07BC"));
    updateStars = (void (*)(void *, int32_t, void *))getRealOffset(
        ENCRYPTOFFSET("0x6A03E4"));
    triggerMoveChanged = (void (*)(void *, int32_t, void *))getRealOffset(
        ENCRYPTOFFSET("0x45347C"));
}

- (void)loadSetting {
    isActiveCoin = [common boolForKey:@"isActiveCoin" defaultValue:NO];
    coins = [common integerForKey:@"Coins" defaultValue:0];
    isActiveStar = [common boolForKey:@"isActiveStar" defaultValue:NO];
    stars = [common integerForKey:@"Stars" defaultValue:0];
    isActiveMove = [common boolForKey:@"isActiveMove" defaultValue:NO];
    moves = [common integerForKey:@"Moves" defaultValue:0];
}

- (void)setupFloatButton {
    [self.floatButtonImageView removeFromSuperview];
    self.floatButtonImageView = nil;
    self.floatButtonHostView = nil;

    NSString *pureBase64 = floatButton;
    if ([pureBase64 hasPrefix:@"data:"]) {
        NSArray *components = [pureBase64 componentsSeparatedByString:@","];
        if (components.count > 1)
            pureBase64 = components[1];
    }
    NSData *data = [[NSData alloc]
        initWithBase64EncodedString:pureBase64
                            options:
                                NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:data];
    if (!image)
        return;

    UIView *hostView = self.view.superview;
    if (!hostView) {
        UIWindow *keyWindow = [common getKeyWindow];
        UIViewController *topVC = [common getTopViewController:keyWindow];
        hostView = topVC.view;
    }
    if (!hostView)
        return;

    self.floatButtonHostView = hostView;

    CGRect bounds = hostView.bounds;
    CGFloat x = (bounds.size.width - kFloatButtonWidth) / 2;
    CGFloat y = (bounds.size.height - kFloatButtonHeight) / 2;

    self.floatButtonImageView = [[UIImageView alloc]
        initWithFrame:CGRectMake(x, y, kFloatButtonWidth, kFloatButtonHeight)];
    self.floatButtonImageView.image = image;
    self.floatButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.floatButtonImageView.layer.cornerRadius = kFloatButtonWidth / 2;
    self.floatButtonImageView.clipsToBounds = YES;
    self.floatButtonImageView.userInteractionEnabled = YES;

    [hostView addSubview:self.floatButtonImageView];
    [hostView bringSubviewToFront:self.floatButtonImageView];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handlePanFloatButton:)];
    [self.floatButtonImageView addGestureRecognizer:panGesture];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handleTapFloatButton)];
    [self.floatButtonImageView addGestureRecognizer:tapGesture];
}

- (void)handlePanFloatButton:(UIPanGestureRecognizer *)gesture {
    UIView *hostView =
        self.floatButtonHostView ?: self.floatButtonImageView.superview;
    if (!hostView)
        return;

    CGPoint translation = [gesture translationInView:hostView];

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect bounds = hostView.bounds;
        CGFloat minX = (kFloatButtonWidth / 2) + kPaddingVertical;
        CGFloat maxX =
            bounds.size.width - (kFloatButtonWidth / 2) - kPaddingVertical;
        CGFloat minY = (kFloatButtonHeight / 2) + kPaddingVertical;
        CGFloat maxY =
            bounds.size.height - (kFloatButtonHeight / 2) - kPaddingVertical;
        CGPoint newCenter =
            CGPointMake(self.floatButtonImageView.center.x + translation.x,
                        self.floatButtonImageView.center.y + translation.y);
        newCenter.x = fmax(minX, fmin(newCenter.x, maxX));
        newCenter.y = fmax(minY, fmin(newCenter.y, maxY));
        self.floatButtonImageView.center = newCenter;

        [gesture setTranslation:CGPointZero inView:hostView];
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [self snapFloatButtonToEdgeAtFirst:NO];
    }
}

- (void)snapFloatButtonToEdgeAtFirst:(BOOL)atFirst {
    UIView *hostView =
        self.floatButtonHostView ?: self.floatButtonImageView.superview;
    if (!hostView)
        return;

    CGRect bounds = hostView.bounds;
    CGRect frame = self.floatButtonImageView.frame;
    CGFloat targetX =
        (self.floatButtonImageView.center.x < bounds.size.width / 2)
            ? kPaddingHorizontal
            : bounds.size.width - frame.size.width - kPaddingHorizontal;
    CGFloat targetY =
        (self.floatButtonImageView.center.y < bounds.size.height / 2)
            ? kPaddingVertical
            : bounds.size.height - frame.size.height - kPaddingVertical;
    CGFloat spaceX = fabs(targetX - self.floatButtonImageView.frame.origin.x);
    CGFloat spaceY = fabs(targetY - self.floatButtonImageView.frame.origin.y);

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                       CGRect finalFrame = self.floatButtonImageView.frame;
                       if (atFirst || spaceX < spaceY) {
                           finalFrame.origin.x = targetX;
                       } else {
                           finalFrame.origin.y = targetY;
                       }
                       self.floatButtonImageView.frame = finalFrame;
                     }
                     completion:nil];
}

- (void)handleTapFloatButton {
    if (self.onCallChange) {
        isShowMenu = !isShowMenu;
        self.onCallChange(isShowMenu);
    }
    [self.floatButtonImageView.superview
        bringSubviewToFront:self.floatButtonImageView];

    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleLight];
    [generator impactOccurred];
}

- (void)hook {
    LOG(@"%@", NSSENCRYPT("========= Start hooking ========="));

    HOOK_V3(
        Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge_Offset,
        Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge,
        _Royal_Scenes_Home_Ui_Sections_Home_InventoryPanel_LifeInfoView__ArrangeInboxBadge);

    HOOK_V3(Game_Levels_Units_MoveManager__SetMaxMoves_Offset,
            Royal_Scenes_Game_Levels_Units_MoveManager__SetMaxMoves,
            _Royal_Scenes_Game_Levels_Units_MoveManager__SetMaxMoves);

    HOOK_V3(Game_Levels_Units_MoveManager__SetMovesForStart_Offset,
            Royal_Scenes_Game_Levels_Units_MoveManager__SetMovesForStart,
            _Royal_Scenes_Game_Levels_Units_MoveManager__SetMovesForStart);

    [self finishHook];
}

- (void)finishHook {
    timer(1) {
        self.hookingDone = YES;

        [self
            activeHack:NSSENCRYPT(
                           "Chào bạn nhé! Mình BỆU đây -.- (Royal Match Hack)")
               message:NSSENCRYPT(
                           "Chạm vào biểu tượng nổi ở trên màn hình, hoặc nhấn "
                           "giữ màn hình 2 lần bằng 3 ngón tay để mở menu.")
                  font:[UIFont fontWithName:NSSENCRYPT("AvenirNext-Bold")
                                       size:15]
              duration:3.0];

        LOG(@"%@", NSSENCRYPT("========= Hooking done ========="));

        [self setupFloatButton];
        timer(0.3) { [self snapFloatButtonToEdgeAtFirst:YES]; });
    });
}

- (void)patch {
    if (!self.hookingDone)
        return;

    // Patch once time
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      timer(0.5) {
          LOG(@"%@", NSSENCRYPT("========= Start patching ========="));
          LOG(@"%@", NSSENCRYPT("========= Patching done ========="));
      });
    });
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

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)hasText {
    return false;
}

- (void)insertText:(NSString *)text {
    if (text.length == 0) {
        return;
    }

    ImGuiIO &io = ImGui::GetIO();
    if (!io.WantTextInput) {
        return;
    }

    if ([text isEqualToString:@"\n"]) {
        io.KeysDown[ImGuiIOSKey_Enter] = true;
        return;
    }

    io.AddInputCharactersUTF8(text.UTF8String);
}

- (void)deleteBackward {
    ImGuiIO &io = ImGui::GetIO();
    io.KeysDown[ImGuiIOSKey_Backspace] = true;
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    if (!ImGui::GetCurrentContext()) {
        return;
    }

    ImGuiIO &io = ImGui::GetIO();
    if (!io.WantTextInput) {
        return;
    }

    self.keyboardDismissedByUser = YES;
    ImGui::ClearActiveID();
}

- (void)syncKeyboardInputState {
    ImGuiIO &io = ImGui::GetIO();

    if (io.WantTextInput) {
        if (!self.keyboardDismissedByUser && ![self isFirstResponder]) {
            [self becomeFirstResponder];
        }
    } else if ([self isFirstResponder]) {
        self.keyboardDismissedByUser = NO;
        [self resignFirstResponder];
    } else {
        self.keyboardDismissedByUser = NO;
    }
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
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
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer
            renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();

        ImFont *font = ImGui::GetFont();
        font->Scale = 15.f / font->FontSize;

        bool isIpad = ([[UIDevice currentDevice] userInterfaceIdiom] ==
                       UIUserInterfaceIdiomPad);

        CGFloat width = fmin(kWidth * (isIpad ? 0.5 : 0.8), 600);
        CGFloat height = fmin(kHeight * (isIpad ? 0.6 : 0.8), 600);
        CGFloat x = (kWidth - width) / 2;
        CGFloat y = (kHeight - height) / 2;

        static float lastKnownWidth = 0;
        static float lastKnownHeight = 0;

        if (supportRotateScreen &&
            (lastKnownWidth != kWidth || lastKnownHeight != kHeight)) {
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Always);
            ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_Always);

            lastKnownWidth = kWidth;
            lastKnownHeight = kHeight;
        } else {
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Appearing);
            ImGui::SetNextWindowSize(ImVec2(width, height),
                                     ImGuiCond_Appearing);
        }

        if (isShowMenu) {
            ImGui::Begin("Royal Match Mod", &isShowMenu);
            ImGui::TextWrapped("Click the floating icon on the screen to open "
                               "or close the menu.\n"
                               "Alternatively, use three fingers to double-tap "
                               "to open the menu, or "
                               "two fingers to double-tap to hide the menu.");
            ImGui::TextWrapped(
                "Bấm vào icon nổi trên màn hình để mở hoặc đóng menu.\n"
                "Hoặc dùng 3 ngón chạm 2 lần để mở menu, 2 ngón chạm "
                "2 lần để ẩn menu\n\n");

            ImGui::TextWrapped(
                "Click on the type you want to mod + adjust the quantity you "
                "want to "
                "mod.\n"
                "Then click Apply, the game will update automatically.");
            ImGui::TextWrapped(
                "Chọn thể loại muốn mod + kéo thanh điều chỉnh số lượng muốn "
                "mod.\n"
                "Sau đó bấm Áp dụng, trò chơi sẽ tự động cập nhật.\n\n");

            ImGui::Checkbox("Coins (Vàng)", &isActiveCoin);
            ImGui::SliderInt("##_Coins", &coins, 0, 999999);
            ImGui::Text("\n");
            ImGui::Checkbox("Stars (Sao)", &isActiveStar);
            ImGui::SliderInt("##_Stars", &stars, 0, 9999);
            ImGui::Text("\n");
            ImGui::Checkbox("Moves (Lượt chơi trong mỗi màn)", &isActiveMove);
            if (ImGui::Button(" - ")) {
                moves = fmax(0, moves - 1);
            }
            ImGui::SameLine();
            ImGui::SliderInt("##_Moves", &moves, 0, 9999);
            ImGui::SameLine();
            if (ImGui::Button(" + ")) {
                moves = fmin(moves + 1, 9999);
            }
            ImGui::Text("\n");

            if (ImGui::Button("Apply / Áp dụng")) {
                applyMod();
                [common setBool:isActiveCoin forKey:@"isActiveCoin"];
                [common setBool:isActiveStar forKey:@"isActiveStar"];
                [common setBool:isActiveMove forKey:@"isActiveMove"];
                if (isActiveCoin) {
                    [common setInt:coins forKey:@"Coins"];
                }
                if (isActiveStar) {
                    [common setInt:stars forKey:@"Stars"];
                }
                if (isActiveMove) {
                    [common setInt:moves forKey:@"Moves"];
                }
            }

            ImGui::TextWrapped("\nFPS: %.1f", ImGui::GetIO().Framerate);

            ImGui::End();
        }

        [self syncKeyboardInputState];
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

    ImGuiIO &resetIO = ImGui::GetIO();
    resetIO.KeysDown[ImGuiIOSKey_Backspace] = false;
    resetIO.KeysDown[ImGuiIOSKey_Enter] = false;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
}

// Show notify
- (void)activeHack:(NSString *)title
           message:(NSString *)message
              font:(UIFont *)font
          duration:(NSTimeInterval)duration {
    static BOOL isShowingNotification = NO;

    if (isShowingNotification) {
        [self hideCurrentNotification];
        isShowingNotification = NO;
    }

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat maxWidth = screenWidth * 0.75;

    UILabel *titleLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, 0)];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = font;
    titleLabel.textColor = [UIColor colorWithRed:0.2
                                           green:0.8
                                            blue:0.2
                                           alpha:1.0];
    titleLabel.numberOfLines = 0;
    [titleLabel sizeToFit];

    UILabel *messageLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, 0)];
    messageLabel.text = message;
    messageLabel.textAlignment = NSTextAlignmentLeft;
    messageLabel.font = [UIFont fontWithName:NSSENCRYPT("AvenirNext-Bold")
                                        size:10];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.numberOfLines = 0;
    [messageLabel sizeToFit];

    CGFloat rectWidth =
        MAX(titleLabel.frame.size.width, messageLabel.frame.size.width) + 60;
    CGFloat rectHeight =
        titleLabel.frame.size.height + messageLabel.frame.size.height + 16;
    CGFloat rectX = screenWidth;
    CGFloat rectY = screenHeight * 0.10;

    UIWindow *mainWindow =
        [[[UIApplication sharedApplication] delegate] window];

    UIView *rect2 =
        [[UIView alloc] initWithFrame:CGRectMake(rectX, rectY, 0, rectHeight)];
    rect2.backgroundColor = [UIColor blackColor];
    [mainWindow addSubview:rect2];

    UIView *rect1 =
        [[UIView alloc] initWithFrame:CGRectMake(rectX, rectY, 0, rectHeight)];
    rect1.backgroundColor = [UIColor colorWithRed:0.2
                                            green:0.8
                                             blue:0.2
                                            alpha:1.0];
    [mainWindow addSubview:rect1];

    [UIView animateWithDuration:0.5
        animations:^{
          rect1.frame =
              CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
          rect2.frame =
              CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
        }
        completion:^(BOOL finished) {
          [UIView animateWithDuration:0.15
              delay:0.0
              options:0
              animations:^{
                rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY,
                                         screenWidth * 0.005, rectHeight);
              }
              completion:^(BOOL finished) {
                titleLabel.alpha = 1;
                messageLabel.alpha = 1;
                [mainWindow addSubview:titleLabel];
                [mainWindow addSubview:messageLabel];
                titleLabel.center =
                    CGPointMake(rectX - rectWidth / 2 + 12,
                                rectY + rectHeight / 2 -
                                    messageLabel.frame.size.height / 2 - 2);
                messageLabel.center =
                    CGPointMake(rectX - rectWidth / 2 + 12,
                                rectY + rectHeight / 2 +
                                    titleLabel.frame.size.height / 2 + 2);

                isShowingNotification = YES;

                [UIView animateWithDuration:0.5
                    delay:duration
                    options:0
                    animations:^{
                      rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY,
                                               rectWidth, rectHeight);
                      titleLabel.center = CGPointMake(
                          rectX + rectWidth / 2 + 12,
                          rectY + rectHeight / 2 -
                              messageLabel.frame.size.height / 2 - 2);
                      messageLabel.center =
                          CGPointMake(rectX + rectWidth / 2 + 12,
                                      rectY + rectHeight / 2 +
                                          titleLabel.frame.size.height / 2 + 2);
                    }
                    completion:^(BOOL finished) {
                      [UIView animateWithDuration:0.15
                          delay:0.0
                          options:0
                          animations:^{
                            rect1.frame =
                                CGRectMake(rectX, rectY, 0, rectHeight);
                            rect2.frame =
                                CGRectMake(rectX, rectY, 0, rectHeight);
                            titleLabel.alpha = 0;
                            messageLabel.alpha = 0;
                          }
                          completion:^(BOOL finished) {
                            [rect1 removeFromSuperview];
                            [rect2 removeFromSuperview];
                            [titleLabel removeFromSuperview];
                            [messageLabel removeFromSuperview];
                          }];
                    }];
              }];
        }];
}

- (void)hideCurrentNotification {
    UIWindow *mainWindow = [common getKeyWindow];

    for (UIView *view in mainWindow.subviews) {
        if ([view isKindOfClass:[UIView class]] && view.backgroundColor) {
            [UIView animateWithDuration:0.15
                animations:^{
                  view.frame =
                      CGRectMake(view.frame.origin.x, view.frame.origin.y, 0,
                                 view.frame.size.height);
                }
                completion:^(BOOL finished) {
                  [view removeFromSuperview];
                }];
        }
    }

    for (UIView *view in mainWindow.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            [UIView animateWithDuration:0.15
                animations:^{
                  view.alpha = 0;
                }
                completion:^(BOOL finished) {
                  [view removeFromSuperview];
                }];
        }
    }
}

// Show alert
- (void)alertWithTitle:(NSString *)title
               message:(NSString *)message
           actionTitle:(NSString *)actionTitle
           actionStyle:(UIAlertActionStyle)actionStyle
               handler:(void (^__nullable)(UIAlertAction *action))handler {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle
                                                     style:actionStyle
                                                   handler:handler];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
