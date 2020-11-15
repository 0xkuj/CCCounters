ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CCCounters
CCCounters_FILES = Tweak.xm
CCCounters_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += cccountersprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
