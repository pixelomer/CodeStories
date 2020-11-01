MINIMUM_IOS = 13.0
TARGET := iphone:clang:latest:$(MINIMUM_IOS)
ARCHS = arm64
export TARGET ARCHS

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = CodeStories

CodeStories_FILES = $(wildcard *.m) $(wildcard FLAnimatedImage/*.m)
CodeStories_FRAMEWORKS = UIKit CoreGraphics
CodeStories_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/application.mk
