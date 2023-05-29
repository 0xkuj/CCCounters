ARCHS = arm64 arm64e
TARGET := iphone:clang:14.5:14.5
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CCCountersPrefs
CCCountersPrefs_FILES = CCCRootListController.m CCCColorPickerCell.m
CCCountersPrefs_INSTALL_PATH = /Library/PreferenceBundles
CCCountersPrefs_FRAMEWORKS = UIKit
CCCountersPrefs_PRIVATE_FRAMEWORKS = Preferences
CCCountersPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CCCountersPrefs.plist$(ECHO_END)
