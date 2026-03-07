TARGET := iphone:clang:latest:10.0
INSTALL_TARGET_PROCESSES = RoyalMatch
FINALPACKAGE = 1
ARCHS = arm64
_IGNORE_WARNINGS = 0
_JAILBREAK = 0 # (0: non-jailbreak, 1: jailbreak)

THEOS_PACKAGE_SCHEME = rootless

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
THEOS_PACKAGE_DIR = rootless
else ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
THEOS_PACKAGE_DIR = roothide
else
THEOS_PACKAGE_DIR = rootful
endif

KITTYMEMORY_SRC = $(wildcard KittyMemory/*.cpp)
IMGUI_SRC = $(wildcard IMGUI/*.cpp) $(wildcard IMGUI/*.mm)
ESP_SRC = $(wildcard Esp/*.m)
COMMON_SRC = Common.mm
ifeq ($(strip $(_JAILBREAK)),1)
DOBBY_SRC = lib/libdobby.a
else
DOBBY_SRC = lib/libdobby_v2.a
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RoyalMatchMod

$(TWEAK_NAME)_FRAMEWORKS = Foundation UIKit
$(TWEAK_NAME)_FILES = ImGuiDrawView.mm $(KITTYMEMORY_SRC) $(COMMON_SRC) $(IMGUI_SRC) $(ESP_SRC)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_CCFLAGS = -std=c++17 -DkITTYMEMORY_DEBUG
$(TWEAK_NAME)_LDFLAGS = $(DOBBY_SRC)

ifeq ($(strip $(_JAILBREAK)),1)
$(TWEAK_NAME)_CCFLAGS += -DkJAILBREAK
endif

ifeq ($(strip $(_IGNORE_WARNINGS)),1)
$(TWEAK_NAME)_CCFLAGS += -w
endif

include $(THEOS_MAKE_PATH)/tweak.mk
