/* This tweak will add countdown indicators to your CC with special handling to Alarm/Timer.
Created by: 0xkuj */

#import <libcolorpicker.h>
#define MODULE_LABELS_PATH @"/var/mobile/Library/Preferences/com.0xkuj.cccounters_modules.plist"
#define GENERAL_PREFS @"/var/mobile/Library/Preferences/com.0xkuj.cccountersprefs.plist"

@interface SBScheduledAlarmObserver
+(id)sharedInstance;
@end

@interface MTAlarm : NSObject
-(BOOL)isActiveAndEnabledForThisDevice;
-(NSDate *)nextFireDate;
@end

@interface CCUIContentModuleContainerView
- (void)setAlpha:(CGFloat)alpha;
- (CGRect)frame;
- (void)addSubview:(id)arg1;
- (id)containerView;
- (void)viewWillAppear:(BOOL)arg1;
@end

@interface CCUIModuleCollectionViewController
// %new
- (NSString *)timeFromSec:(int)seconds;
// %new
-(void)addLastTimePressedLabel:(id)moduleID;
// %new
-(void)addInitialLabels;
// %new 
-(void)addTimerLabel;
// %new
-(void)addAlarmLabel;
// %new
-(UIColor*)randColor;
@end

@interface MTTimer 
@property (nonatomic,readonly) double remainingTime; 
@property (nonatomic,readonly) NSDate * fireDate; 
@property (nonatomic,readonly) NSDate * firedDate; 
@property (nonatomic,readonly) unsigned long long state; 
-(BOOL)isCurrentTimer;
@end

@protocol MTTimerManagerIntentSupport 
@end

@interface MTTimerManager : NSObject
@property (copy,readonly) NSString * description; 
@property (nonatomic,readonly) id<MTTimerManagerIntentSupport> timerManager; 
@property (nonatomic,retain) NSNotificationCenter * notificationCenter;  
-(id)initWithMetrics:(id)arg1 ;
-(id)init;
-(id)nextTimer;
-(id)pauseCurrentTimer;
-(id)currentTimer;
-(id)getCurrentTimerSync;
-(id)timersSync;
-(id)timers;
-(id)updateTimer:(id)arg1 ;
@end

@interface MTTimerManagerExportedObject
@property (nonatomic,readonly) MTTimerManager * timerManager;   
@property (copy,readonly) NSString * description;
@end

@interface NAFuture {
	id _resultValue;
}
@end

@interface CCUIModuleCollectionView
@end

@interface CCUIContentModuleContainerViewController
@property (nonatomic,copy) NSString * moduleIdentifier;
-(BOOL)isExpanded;
-(void)hideLabel:(BOOL)hide;
@end

UILabel *timeRemainingLabel;
UILabel *alarmRemainingLabel;
NSDate *pendingDateTimer;
NSDate* pendingDateAlarm;
CCUIContentModuleContainerView *timerModuleContainerView;
NSTimer* pendingTimer;
NSTimer* pendingTimerAlarm;
MTTimer* globalPointerToNAF;
static BOOL dismissingCC = FALSE,timerExpanded = FALSE;
BOOL isEnabled = TRUE,isAlarmETA = TRUE,isTimerETA = TRUE,isLastPressed = FALSE,isStyleAlarmColorRand = FALSE,isStyleTimerColorRand = FALSE,isStyleLastPressedColorRand = FALSE;
NSString *styleAlarmColor = nil, *styleTimerColor = nil, *styleLastPressedColor = nil;
static int singleInit = 0;
NSMutableDictionary* moduleAndLabels;
NSDictionary *moduleDictionary;
UILabel *alarmLabel;
MTTimerManager* globlmtmanager;

/* Load preferences after change */
static void loadPrefs() {
	NSMutableDictionary* mainPreferenceDict = [[NSMutableDictionary alloc] initWithContentsOfFile:GENERAL_PREFS];
	if ([mainPreferenceDict objectForKey:@"isEnabled"] != nil) {
		isEnabled = [[mainPreferenceDict objectForKey:@"isEnabled"] boolValue];
	}

	if ([mainPreferenceDict objectForKey:@"isAlarmETA"] != nil) {
		isAlarmETA = [[mainPreferenceDict objectForKey:@"isAlarmETA"] boolValue];
	}
	if ([mainPreferenceDict objectForKey:@"isTimerETA"] != nil) {
		isTimerETA = [[mainPreferenceDict objectForKey:@"isTimerETA"] boolValue];
	}
	if ([mainPreferenceDict objectForKey:@"isLastPressed"] != nil) {
		isLastPressed = [[mainPreferenceDict objectForKey:@"isLastPressed"] boolValue];
	}
	if ([mainPreferenceDict objectForKey:@"isStyleAlarmColorRand"] != nil) {
		isStyleAlarmColorRand = [[mainPreferenceDict objectForKey:@"isStyleAlarmColorRand"] boolValue];
	}
	if ([mainPreferenceDict objectForKey:@"isStyleTimerColorRand"] != nil) {
		isStyleTimerColorRand = [[mainPreferenceDict objectForKey:@"isStyleTimerColorRand"] boolValue];
	}
	if ([mainPreferenceDict objectForKey:@"isStyleLastPressedColorRand"] != nil) {
		isStyleLastPressedColorRand = [[mainPreferenceDict objectForKey:@"isStyleLastPressedColorRand"] boolValue];
	}
	  if ([mainPreferenceDict objectForKey:@"styleAlarmColor"] != nil) {
		styleAlarmColor = [mainPreferenceDict objectForKey:@"styleAlarmColor"];
	}
	  if ([mainPreferenceDict objectForKey:@"styleTimerColor"] != nil) {
		styleTimerColor = [mainPreferenceDict objectForKey:@"styleTimerColor"];
	}
	  if ([mainPreferenceDict objectForKey:@"styleLastPressedColor"] != nil) {
		styleLastPressedColor = [mainPreferenceDict objectForKey:@"styleLastPressedColor"];
	}

}

%hook MTTimerManager   
/* Get timer instances when system loads up */
-(MTTimerManagerExportedObject *)exportedObject {
	if (!isEnabled) {
		return %orig;
	}
	MTTimerManagerExportedObject* expManager = %orig;
	globlmtmanager = expManager.timerManager;
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

/* By design - will change if requested - module engagement - touch is sufficient */
%hook CCUIModuleCollectionViewController
static BOOL timerWasExpended = FALSE;
-(void)contentModuleContainerViewController:(id)arg1 didBeginInteractionWithModule:(id)arg2 {
	if (!isEnabled) {
		%orig;
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
		%orig;
		return;
	}

	%orig(arg1);
	if (timerWasExpended && isTimerETA) {
		[self addTimerLabel];
	}
}

-(void)viewWillAppear:(BOOL)arg1 {
	if (!isEnabled) {
		%orig;
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
				[moduleDateLabel setTextColor:LCPParseColorString(styleLastPressedColor, @"#FFFFFF")];
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
				[alarmRemainingLabel setTextColor:LCPParseColorString(styleAlarmColor, @"#FFFFFF")];
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
	if (globlmtmanager) {
		MTTimer* crTimer = [globlmtmanager currentTimer];
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
				[timeRemainingLabel setTextColor:LCPParseColorString(styleTimerColor, @"#FFFFFF")];
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
		[lastPressedLabel setTextColor:LCPParseColorString(styleLastPressedColor, @"#FFFFFF")];
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
