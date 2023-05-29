ARCHS = arm64 arm64e
TARGET := iphone:clang:14.5:14.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CCCounters
CCCounters_FILES = $(wildcard CCC*.x*)
CCCounters_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += cccountersprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
