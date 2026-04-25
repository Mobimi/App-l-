# ÉP CỨNG KIẾN TRÚC CHO CHẮC CỐP
ARCHS = arm64 arm64e

TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = PerformanceHUD

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = PerformanceHUD

PerformanceHUD_FILES = main.m
PerformanceHUD_FRAMEWORKS = UIKit CoreGraphics
PerformanceHUD_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
