TARGET := iphone:clang:latest:12.4
GO_EASY_ON_ME=1

ARCHS = arm64
THEOS_DEVICE_IP = 172.30.1.54 -p 22

include $(THEOS)/makefiles/common.mk

TOOL_NAME = machotest

machotest_FILES = main3.m
machotest_CFLAGS = -fobjc-arc
machotest_CODESIGN_FLAGS = -Sentitlements.plist
machotest_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
