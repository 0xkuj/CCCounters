/* This tweak will add countdown indicators to your CC with special handling to Alarm/Timer.
 * Bonus: this tweak survives resprings!
Created by: 0xkuj */
#define MODULE_LABELS_PATH ROOT_PATH_NS(@"/var/mobile/Library/Preferences/com.0xkuj.cccounters_modules.plist")
#define GENERAL_PREFS ROOT_PATH_NS(@"/var/mobile/Library/Preferences/com.0xkuj.cccountersprefs.plist")
#include "CCCounters.h"

@interface NSMutableDictionary (ContactsExtended)
-(UIColor *)colorWithHexString:(NSString*)hex;
@end

@implementation NSMutableDictionary (ContactsExtended)
-(UIColor *)colorWithHexString:(NSString*)hex {
  if ([hex isEqualToString:@"red"]) {
    return UIColor.systemRedColor;
  } else if ([hex isEqualToString:@"orange"]) {
    return UIColor.systemOrangeColor;
  } else if ([hex isEqualToString:@"yellow"]) {
    return UIColor.systemYellowColor;
  } else if ([hex isEqualToString:@"green"]) {
    return UIColor.systemGreenColor;
  } else if ([hex isEqualToString:@"blue"]) {
    return UIColor.systemBlueColor;
  } else if ([hex isEqualToString:@"teal"]) {
    return UIColor.systemTealColor;
  } else if ([hex isEqualToString:@"indigo"]) {
    return UIColor.systemIndigoColor;
  } else if ([hex isEqualToString:@"purple"]) {
    return UIColor.systemPurpleColor;
  } else if ([hex isEqualToString:@"pink"]) {
    return UIColor.systemPinkColor;
  } else if ([hex isEqualToString:@"default"]) {
    return UIColor.labelColor;
  } else if ([hex isEqualToString:@"tertiary"]) {
    return UIColor.tertiaryLabelColor;
  } else {

    NSString *cleanString = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
      cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
      [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
      [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
      [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
      cleanString = [cleanString stringByAppendingString:@"ff"];
    }

    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];

    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
  }
}
@end

/* Load preferences after change */
static void loadPrefs() {
	NSMutableDictionary* mainPreferenceDict = [[NSMutableDictionary alloc] initWithContentsOfFile:GENERAL_PREFS];
    isEnabled = ([mainPreferenceDict objectForKey:@"isEnabled"] != nil) ? [[mainPreferenceDict objectForKey:@"isEnabled"] boolValue] : TRUE;
    isAlarmETA = ([mainPreferenceDict objectForKey:@"isAlarmETA"] != nil) ? [[mainPreferenceDict objectForKey:@"isAlarmETA"] boolValue] : TRUE;
    isTimerETA = ([mainPreferenceDict objectForKey:@"isTimerETA"] != nil) ? [[mainPreferenceDict objectForKey:@"isTimerETA"] boolValue] : TRUE;
    isLastPressed = ([mainPreferenceDict objectForKey:@"isLastPressed"] != nil) ? [[mainPreferenceDict objectForKey:@"isLastPressed"] boolValue] : FALSE;
    isStyleAlarmColorRand = ([mainPreferenceDict objectForKey:@"isStyleAlarmColorRand"] != nil) ? [[mainPreferenceDict objectForKey:@"isStyleAlarmColorRand"] boolValue] : FALSE;
    isStyleTimerColorRand = ([mainPreferenceDict objectForKey:@"isStyleTimerColorRand"] != nil) ? [[mainPreferenceDict objectForKey:@"isStyleTimerColorRand"] boolValue] : FALSE;
    isStyleLastPressedColorRand = ([mainPreferenceDict objectForKey:@"isStyleLastPressedColorRand"] != nil) ? [[mainPreferenceDict objectForKey:@"isStyleLastPressedColorRand"] boolValue] : FALSE;

	if ([mainPreferenceDict objectForKey:@"styleAlarmColor"] != nil) {
		styleAlarmColor = [mainPreferenceDict colorWithHexString:[mainPreferenceDict objectForKey:@"styleAlarmColor"]];
	} else {
		styleAlarmColor = [UIColor whiteColor];
	}

	if ([mainPreferenceDict objectForKey:@"styleTimerColor"] != nil) {
		styleTimerColor = [mainPreferenceDict colorWithHexString:[mainPreferenceDict objectForKey:@"styleTimerColor"]];
	} else {
		styleTimerColor = [UIColor whiteColor];
	}

	if ([mainPreferenceDict objectForKey:@"styleLastPressedColor"] != nil) {
		styleLastPressedColor = [mainPreferenceDict colorWithHexString:[mainPreferenceDict objectForKey:@"styleLastPressedColor"]];
	} else {
		styleLastPressedColor = [UIColor whiteColor];
	}
}

%hook MTTimerManager   
//this was the same but for currentTimer
-(MTTimerManagerExportedObject *)exportedObject {
	if (!isEnabled) {
		return %orig;
	}
	MTTimerManagerExportedObject* expManager = %orig;
	globalTimerMgr = expManager.timerManager;
	if (singleInit == 0) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([fileManager fileExistsAtPath:MODULE_LABELS_PATH]){ 
			moduleAndLabels =  [[NSMutableDictionary alloc] initWithContentsOfFile:MODULE_LABELS_PATH];
		} else {
			moduleAndLabels = [[NSMutableDictionary alloc] init];
		}
		singleInit++;
	}
	return expManager;
}
%end

%hook CCUIModuleCollectionViewController
static BOOL timerWasExpended = FALSE;
-(void)contentModuleContainerViewController:(id)arg1 didBeginInteractionWithModule:(id)arg2 {
	if (!isEnabled) {
		%orig(arg1,arg2);
		return;
	}

	 %orig(arg1,arg2); 
	 NSString* mdForCompare = ((CCUIContentModuleContainerViewController*)arg1).moduleIdentifier;
	 //do nothing for those modules for now.
	 if ([mdForCompare isEqualToString:@"com.apple.mediaremote.controlcenter.nowplaying"] || [mdForCompare isEqualToString:@"com.apple.control-center.ConnectivityModule"]) {
		 return;
	 }
	 [self addLastTimePressedLabel:arg1];
	 if ([mdForCompare isEqualToString:@"com.apple.mobiletimer.controlcenter.timer"]) {
		 timerWasExpended = TRUE;
	 } else {
		 timerWasExpended = FALSE;
	 }
}

-(void)contentModuleContainerViewControllerDismissPresentedContent:(id)arg1 {
	if (!isEnabled) {
		%orig(arg1);
		return;
	}

	%orig(arg1);
	if (timerWasExpended && isTimerETA) {
		[self addTimerLabel];
	}
}

-(void)viewWillAppear:(BOOL)arg1 {
	if (!isEnabled) {
		%orig(arg1);
		return;
	}

	%orig(arg1);
	moduleDictionary = MSHookIvar<NSDictionary *>(self, "_moduleContainerViewByIdentifier");
	[self addInitialLabels];
	return;
}

/* Adding labels from the user saved plist file */
%new 
-(void)addInitialLabels {

	if (isLastPressed) {
		for(id key in moduleAndLabels) {
			CCUIContentModuleContainerView *moduleView = [moduleDictionary objectForKey:key];
			UILabel* moduleDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4.5, moduleView.frame.size.width,12)];
			[moduleDateLabel setText:[moduleAndLabels objectForKey:key]];
			[moduleDateLabel setFont:[UIFont systemFontOfSize:7]];
			if (isStyleLastPressedColorRand) {
				[moduleDateLabel setTextColor:[self randColor]];
			} else {
				[moduleDateLabel setTextColor:styleLastPressedColor];
			}
			[moduleDateLabel setTextAlignment:NSTextAlignmentCenter];
			[moduleView addSubview:moduleDateLabel];
		}
	}
	if (isTimerETA) {
		[self addTimerLabel];
	}
	if (isAlarmETA) {
		[self addAlarmLabel];
	}
}
%new 
-(UIColor*)randColor {
	CGFloat r   = arc4random_uniform(255)/255.0;  
	CGFloat g 	= arc4random_uniform(255)/255.0;  
	CGFloat b   = arc4random_uniform(255)/255.0;  
	return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}
/* adding special alarm label that shows the ETA for the closest alarm */
%new
-(void)addAlarmLabel {
	/* ALARM HANDLING! */
	CCUIContentModuleContainerView* alarmModuleContainerView = [moduleDictionary objectForKey:@"com.apple.control-center.AlarmModule"];
    MTAlarm *nextAlarm = [[[[%c(SBScheduledAlarmObserver) sharedInstance] valueForKey:@"_alarmManager"] valueForKey:@"_cache"] valueForKey:@"_nextAlarm"];
    if(nextAlarm){
		pendingDateAlarm = [nextAlarm nextFireDate];
		int timeDelta = [pendingDateAlarm timeIntervalSinceDate:[NSDate date]];
		if (timeDelta > 0) {
			//[[alarmModuleContainerView containerView] setAlpha:0.25f];
			if (alarmRemainingLabel) {
				[alarmRemainingLabel removeFromSuperview];
				alarmRemainingLabel = nil;
			}
			//timeRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [timerModuleContainerView frame].size.width, [timerModuleContainerView frame].size.height)];
			alarmRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, alarmModuleContainerView.frame.size.height-18, [alarmModuleContainerView frame].size.width, 12)];
			[alarmRemainingLabel setText:[self timeFromSec:timeDelta]];
			[alarmRemainingLabel setFont:[UIFont systemFontOfSize:10]];
			if (isStyleAlarmColorRand) {
				[alarmRemainingLabel setTextColor:[self randColor]];
			} else {
				[alarmRemainingLabel setTextColor:styleAlarmColor];
			}
			[alarmRemainingLabel setTextAlignment:NSTextAlignmentCenter];
			[alarmModuleContainerView addSubview:alarmRemainingLabel];
			pendingTimerAlarm = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateLabelAlarm:) userInfo:nil repeats:YES];
		}
	}
}

/* adding special timer albel that shows the ETA for the closest timer */
%new
-(void)addTimerLabel {
	timerModuleContainerView = [moduleDictionary objectForKey:@"com.apple.mobiletimer.controlcenter.timer"];
	if (globalTimerMgr) {
		MTTimer* crTimer = [globalTimerMgr currentTimer];
		MTTimer* _resultVal = MSHookIvar<MTTimer*>(crTimer,"_resultValue");
		pendingDateTimer = _resultVal.fireDate;
		int timeDelta = [pendingDateTimer timeIntervalSinceDate:[NSDate date]];
		if (timeDelta > 0) {
			[[timerModuleContainerView containerView] setAlpha:0.25f];
			if (timeRemainingLabel) {
				[timeRemainingLabel removeFromSuperview];
				timeRemainingLabel = nil;
			}
			timeRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [timerModuleContainerView frame].size.width, [timerModuleContainerView frame].size.height)];
			[timeRemainingLabel setText:[self timeFromSec:timeDelta]];
			[timeRemainingLabel setFont:[UIFont systemFontOfSize:12]];
			if (isStyleTimerColorRand) {
				[timeRemainingLabel setTextColor:[self randColor]];
			} else {
				[timeRemainingLabel setTextColor:styleTimerColor];
			}
			
			[timeRemainingLabel setTextAlignment:NSTextAlignmentCenter];
			[timerModuleContainerView addSubview:timeRemainingLabel];
			pendingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateLabelTimer:) userInfo:nil repeats:YES];
		}
	}
}

/* when module is engaged (being touched) will add updated label above it to show the last time it was pressed - if anyone wants that -.- */
%new
-(void)addLastTimePressedLabel:(id)moduleID {
	if (!isLastPressed) {
		return;
	}
	CCUIContentModuleContainerView *selectedModuleView = [moduleDictionary objectForKey:((CCUIContentModuleContainerViewController*)moduleID).moduleIdentifier];
	for (UIView *subView  in ((UIView*)selectedModuleView).subviews) {
		if ([subView isKindOfClass:[UILabel class]]) {
			if (subView != alarmRemainingLabel && subView != timeRemainingLabel)
				[subView  removeFromSuperview];
		}
	}

	UILabel *lastPressedLabel;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"dd/MM"];
	NSDateFormatter *clockFormatter = [[NSDateFormatter alloc] init];
    [clockFormatter setLocale:[NSLocale currentLocale]];
    [clockFormatter setDateStyle:NSDateFormatterNoStyle];
    [clockFormatter setTimeStyle:NSDateFormatterShortStyle];

	NSString* currentDate = [NSString stringWithFormat:@"%@ - %@",[dateFormatter stringFromDate:[NSDate date]], [clockFormatter stringFromDate:[NSDate date]]];
	lastPressedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4.5, selectedModuleView.frame.size.width,12)];
	[lastPressedLabel setText:currentDate];
	[lastPressedLabel setFont:[UIFont systemFontOfSize:7]];
	if (isStyleLastPressedColorRand) {
		[lastPressedLabel setTextColor:[self randColor]];
	} else {
		[lastPressedLabel setTextColor:styleLastPressedColor];
	}
	
	[lastPressedLabel setTextAlignment:NSTextAlignmentCenter];
	[selectedModuleView addSubview:lastPressedLabel];

	/* saving the text of the current time and date as per module name */
	[moduleAndLabels setObject:lastPressedLabel.text forKey:((CCUIContentModuleContainerViewController*)moduleID).moduleIdentifier];
	[moduleAndLabels writeToFile:MODULE_LABELS_PATH atomically:YES];
}

%new 
- (void)updateLabelAlarm:(NSTimer *)timer {
	if ([pendingDateAlarm timeIntervalSinceDate:[NSDate date]] <= 0) {
		[alarmRemainingLabel removeFromSuperview];
		return;
	}

	[alarmRemainingLabel setText:[self timeFromSec:[pendingDateAlarm timeIntervalSinceDate:[NSDate date]]]];
}

%new
- (void)updateLabelTimer:(NSTimer *)timer {

	if ([pendingDateTimer timeIntervalSinceDate:[NSDate date]] <= 0) {
		[timeRemainingLabel removeFromSuperview];
		timeRemainingLabel = nil;
		[[timerModuleContainerView containerView] setAlpha:1.0f];
		return;
	} 
	[timeRemainingLabel setText:[self timeFromSec:[pendingDateTimer timeIntervalSinceDate:[NSDate date]]]];	
}

%new
- (NSString *)timeFromSec:(int)seconds {
	int hours = floor(seconds /  (60 * 60));
	float minute_divisor = seconds % (60 * 60);
	int minutes = floor(minute_divisor / 60);
	float seconds_divisor = seconds % 60;
	seconds = ceil(seconds_divisor);
	if (hours > 0) {
		return [NSString stringWithFormat:@"%0.2d:%0.2d:%0.2d", hours, minutes, seconds];
	} else {
		return [NSString stringWithFormat:@"%0.2d:%0.2d", minutes, seconds];
	}
}
%end

%hook CCUIContentModuleContainerViewController
-(void)setExpanded:(BOOL)arg1  {
	if (!isEnabled) {
		%orig;
		return;
	}

	 if ([[self moduleIdentifier] isEqualToString:@"com.apple.mobiletimer.controlcenter.timer"]) {
		 timerExpanded = TRUE;
	 }

	 if (arg1) {
		alarmRemainingLabel.hidden = 1;
	 	timeRemainingLabel.hidden = 1;
		[self hideLabel:TRUE];
	 }
	 else {
		alarmRemainingLabel.hidden = 0;
		timeRemainingLabel.hidden = 0;
		[self hideLabel:FALSE];
		timerExpanded = FALSE;
	 }
	 %orig; 
}

%new
-(void)hideLabel:(BOOL)hide {
	for(id key in moduleAndLabels) {
		CCUIContentModuleContainerView *moduleWithLabel = [moduleDictionary objectForKey:key];
		for (UIView *subView  in ((UIView*)moduleWithLabel).subviews) {
			if ([subView isKindOfClass:[UILabel class]]) {
				((UILabel*)subView).hidden = hide;
			}	
		}
	}
}
%end

%hook SBControlCenterController
- (void)_willPresent {
	if (!isEnabled) {
		%orig;
		return;
	}

	%orig;
	dismissingCC = FALSE;
}
- (void)_willDismiss {
	if (!isEnabled) {
		%orig;
		return;
	}

	%orig;
	dismissingCC = TRUE;
	if (timeRemainingLabel) {
		[pendingTimer invalidate];
		pendingTimer = nil;
		[timeRemainingLabel removeFromSuperview];
		timeRemainingLabel = nil;
		[[timerModuleContainerView containerView] setAlpha:1.0f];
	}
	if (alarmRemainingLabel) {
		[pendingTimerAlarm invalidate];
		pendingTimerAlarm = nil;
		[alarmRemainingLabel removeFromSuperview];
	}

	for(id key in moduleAndLabels) {
		CCUIContentModuleContainerView *moduleWithLabel = [moduleDictionary objectForKey:key];
		for (UIView *subView  in ((UIView*)moduleWithLabel).subviews) {
			if ([subView isKindOfClass:[UILabel class]]) {
				[subView removeFromSuperview];
			}	
		}
	}
}
%end

%ctor {
	loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.0xkuj.cccounters.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}
