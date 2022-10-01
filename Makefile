TARGET := iphone:clang:14.4
INSTALL_TARGET_PROCESSES = SpringBoard


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PlayerOutline

PlayerOutline_FILES = Tweak.xm
PlayerOutline_CFLAGS = -fobjc-arc
PlayerOutline_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk
