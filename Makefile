MINIMUM_IOS = 10.0
TARGET := iphone:clang:latest:$(MINIMUM_IOS)
ARCHS = armv7 arm64
export TARGET ARCHS

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = CodeStories

CodeStories_FILES = $(wildcard CodeStories/*.m) $(wildcard Highlightr/*.m)
CodeStories_FRAMEWORKS = UIKit CoreGraphics
CodeStories_CFLAGS = -fobjc-arc -I.

include $(THEOS_MAKE_PATH)/application.mk
