GO_EASY_ON_ME = 1
DEBUG = 0
FINALPACKAGE = 1

THEOS_DEVICE_IP = 127.0.0.1 -p 2222

TARGET := iphone:clang:12.4:12.4
# THEOS_PACKAGE_SCHEME=rootful

ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TOOL_NAME = stage3

stage3_FILES = stage3.m krw.c alert.c rejailbreak.m offsets.m proc.m kutils.c remount.c bootstrap.m NSData+GZip.m start_jailbreakd.m trustcache.m
stage3_CFLAGS = -fobjc-arc
stage3_CODESIGN_FLAGS = -Sentitlements.plist
stage3_FRAMEWORKS = Foundation IOKit Security
stage3_INSTALL_PATH = /usr/local/bin

include $(THEOS_MAKE_PATH)/tool.mk
