#include <RemoteLog.h>
#import <sys/utsname.h>

@interface SBFApplication : NSObject
@property (nonatomic, copy) NSString *applicationBundleIdentifier;
@end

@interface CCUIAppLauncherViewController : UIViewController
-(BOOL)isAlarm;
-(BOOL)isTimer;
@end

@interface SBScheduledAlarmObserver
+(id)sharedInstance;
@end

@interface MTAlarm : NSObject
-(BOOL)isActiveAndEnabledForThisDevice;
-(NSDate *)nextFireDate;
@end

@interface UIDevice (Private)
@property (nonatomic, copy) NSString *hwMachine;
@end

@interface NSTimer (ffs)
+ (id)scheduledTimerWithTimeInterval:(double)arg1 invocation:(id)arg2 repeats:(bool)arg3;
+ (id)scheduledTimerWithTimeInterval:(double)arg1 repeats:(bool)arg2 block:(id /* block */)arg3;
+ (id)scheduledTimerWithTimeInterval:(double)arg1 target:(id)arg2 selector:(SEL)arg3 userInfo:(id)arg4 repeats:(bool)arg5;
@end


@interface TimerManager
+ (instancetype)sharedManager;
@end

@interface UIConcreteLocalNotification
- (NSDate *)fireDate;
@end

@interface SBCCShortcutButtonController
- (void)setHidden:(_Bool)arg1;
- (UIView *)view;
@end

@interface SBCCButtonSectionController
- (NSString *)prettyPrintTime:(int)seconds;
- (void)updateLabel:(NSTimer *)timer;
@end

@interface CCUIContentModuleContainerView
- (void)setAlpha:(CGFloat)alpha;
- (CGRect)frame;
- (void)addSubview:(id)arg1;
- (id)containerView; // this is the clock icon, used to lower the alpha

- (void)viewWillAppear:(BOOL)arg1;
- (void)viewWillDisappear:(BOOL)arg1;
@end

@interface CCUIModuleCollectionViewController
// %new
- (NSString *)prettyPrintTime:(int)seconds;
// %new
- (void)updateLabel:(NSTimer *)timer;
// %new
-(void)addLastTimePressedLabel:(id)moduleID;
@end

@interface MTTimer 
@property (nonatomic,readonly) double remainingTime; 
@property (nonatomic,readonly) NSDate * fireDate; 
@property (nonatomic,readonly) NSDate * firedDate; 
@property (nonatomic,readonly) unsigned long long state; 
-(BOOL)isCurrentTimer;
@end


@interface MTTimerCache
@property (nonatomic,retain) MTTimer * nextTimer;
@property (nonatomic,retain) NSMutableArray * orderedTimers;
-(void)getCachedTimersWithCompletion:(/*^block*/id)arg1 ;
@end

@interface MTMetrics
@property (assign,nonatomic) unsigned long long operationStartTime; 
+(id)_sharedPublicMetrics;
@end
@protocol MTTimerManagerIntentSupport 
@end

@interface MTTimerManager : NSObject
@property (nonatomic,retain) MTTimerCache * cache; 
@property (nonatomic,retain) MTMetrics * metrics;  
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
-(id)notificationObject;
@end

@interface MTTimerManagerExportedObject
@property (nonatomic,readonly) MTTimerManager * timerManager;   
@property (copy,readonly) NSString * description;
@end

@interface NAFuture {
	id _resultValue;
}
@end

@interface UIPreviewInteraction
@end


@interface MTTimerDate
-(id)initWithDate:(id)arg1 ;
-(id)initWithDate:(id)arg1 currentDateProvider:(/*^block*/id)arg2 ;
-(id)initWithCoder:(id)arg1 ;
-(double)remainingTime;
@end

@interface CCUIModuleCollectionView
@end

@interface CCUIContentModuleContext
@end

@interface CCUIContentModuleContainerViewController
@property (nonatomic,copy) NSString * moduleIdentifier;
-(BOOL)isExpanded;
@end
//@interface NSNotificationCenter
//-(id)description;
//@end
UILabel *timeRemainingLabel;
NSDate *pendingDate;
NSTimer *pendingTimer;
SBCCShortcutButtonController *timerButton;
CCUIContentModuleContainerView *timerModuleContainerView;
//double globalRemainTime;
MTTimer* globalPointerToNAF;
static BOOL dismissingCC = FALSE;
static int singleInit = 0;
NSMutableDictionary* moduleAndLabels;
NSDictionary *moduleDictionary;
#define MODULE_LABELS_PATH @"/var/mobile/Library/Preferences/com.0xkuj.cccounters_modules.plist"

#pragma clang diagnostic ignored "-Wunused-variable"

UILabel *alarmLabel;
MTTimerManager* globlmtmanager;
%hook MTTimerManager   
//this was the same but for currentTimer
-(MTTimerManagerExportedObject *)exportedObject {
	MTTimerManagerExportedObject* expManager = %orig;
	globlmtmanager = expManager.timerManager;
	RLog(@"expmanager: %@ actual manager: %@", expManager, expManager.timerManager);
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

//good enough for me. if complains then fix. bug: when touched and not when pressed.
%hook CCUIModuleCollectionViewController
-(void)contentModuleContainerViewController:(id)arg1 didBeginInteractionWithModule:(id)arg2 {
	 %orig(arg1,arg2); 
	 [self addLastTimePressedLabel:arg1];
}
-(void)viewWillAppear:(BOOL)arg1 {
	%orig;

	moduleDictionary = MSHookIvar<NSDictionary *>(self, "_moduleContainerViewByIdentifier");
	RLog(@"omriku prints all modules :%@", moduleDictionary);
	for(id key in moduleAndLabels) {
		CCUIContentModuleContainerView *moduleView = [moduleDictionary objectForKey:key];
		UILabel* moduleDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4.5, moduleView.frame.size.width,12)];
		[moduleDateLabel setText:[moduleAndLabels objectForKey:key]];
		[moduleDateLabel setFont:[UIFont systemFontOfSize:7]];
		[moduleDateLabel setTextColor:[UIColor whiteColor]];
		[moduleDateLabel setTextAlignment:NSTextAlignmentCenter];
		[moduleView addSubview:moduleDateLabel];
		//((UILabel*)[moduleAndLabels objectForKey:key]).hidden = 0;
		//RLog(@"omriku print label: %@", );
	}
	//this works. returns all the modules currently exists on the cc. find a way to see how to hook the selected bmodule .
	timerModuleContainerView = [moduleDictionary objectForKey:@"com.apple.mobiletimer.controlcenter.timer"];

	if (globlmtmanager) {
		MTTimer* blof = [globlmtmanager currentTimer];
		MTTimer* _myresult = MSHookIvar<MTTimer*>(blof,"_resultValue");
		MTTimerCache *cache = [globlmtmanager cache];
		CGFloat remainingTime = cache.nextTimer.remainingTime;
		NSDate* fireDate = cache.nextTimer.fireDate;
		pendingDate = _myresult.fireDate;
		int timeDelta = [pendingDate timeIntervalSinceDate:[NSDate date]];
		if (timeDelta > 0) {
			[[timerModuleContainerView containerView] setAlpha:0.25f];
			if (timeRemainingLabel) {
				[timeRemainingLabel removeFromSuperview];
				timeRemainingLabel = nil;
			}
			timeRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [timerModuleContainerView frame].size.width, [timerModuleContainerView frame].size.height)];
			[timeRemainingLabel setText:[self prettyPrintTime:timeDelta]];
			[timeRemainingLabel setFont:[UIFont systemFontOfSize:12]];
			[timeRemainingLabel setTextColor:[UIColor whiteColor]];
			[timeRemainingLabel setTextAlignment:NSTextAlignmentCenter];
			[timerModuleContainerView addSubview:timeRemainingLabel];
			pendingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateLabel:) userInfo:nil repeats:YES];
	
		}
	}
	return;
}
//works. currnet issue: labels stay after exapnding module. in alarm it works just fine. try to figure out how it works there.
%new
-(void)addLastTimePressedLabel:(id)moduleID {
	//NSDictionary *moduleDictionary = MSHookIvar<NSDictionary *>(self, "_moduleContainerViewByIdentifier");
	//NSDictionary *moduleDictionary = MSHookIvar<NSDictionary *>(self, "_moduleContainerViewByIdentifier");
	//RLog(@"omriku prints whole modules names: %@",moduleDictionary);
	//returns "<CCUIContentModuleContainerViewController:
	CCUIContentModuleContainerView *selectedModuleView = [moduleDictionary objectForKey:((CCUIContentModuleContainerViewController*)moduleID).moduleIdentifier];
	//RLog(@"omriku going to hook the view addr: %@",selectedModuleView);
	for (UIView *subView  in ((UIView*)selectedModuleView).subviews) {
		if ([subView isKindOfClass:[UILabel class]]) {
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
	[lastPressedLabel setTextColor:[UIColor whiteColor]];
	[lastPressedLabel setTextAlignment:NSTextAlignmentCenter];
	[selectedModuleView addSubview:lastPressedLabel];

	[moduleAndLabels setObject:lastPressedLabel.text forKey:((CCUIContentModuleContainerViewController*)moduleID).moduleIdentifier];
	[moduleAndLabels writeToFile:MODULE_LABELS_PATH atomically:YES];
}
%new
- (void)updateLabel:(NSTimer *)timer {
	if ([pendingDate timeIntervalSinceDate:[NSDate date]] <= 0) {
		[timeRemainingLabel removeFromSuperview];
		[[timerModuleContainerView containerView] setAlpha:1.0f];
		return;
	}
	[timeRemainingLabel setText:[self prettyPrintTime:[pendingDate timeIntervalSinceDate:[NSDate date]]]];
}
// giving credit where due
// http://stackoverflow.com/a/7059284/3411191
%new
- (NSString *)prettyPrintTime:(int)seconds {
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
- (void)viewDidDisappear:(BOOL)arg1 {
	[pendingTimer invalidate];
	pendingTimer = nil;
	[timeRemainingLabel removeFromSuperview];
	timeRemainingLabel = nil;
	[[timerModuleContainerView containerView] setAlpha:1.0f];
	%orig;
}
%end
//create nsdictionary of uilabels. key = modulename value = uilabel.
//when reaching here with value of 1, go over this dictionary (after you transform it into array?) and .hidden all uilabels.
//when reaching here with value of 0, go over this dictionary and .hidden = 0 on all labels. 
//decide how the label will look like. dd/MM - HH:mm? optional for only time? think about it.

%hook CCUIContentModuleContainerViewController
-(void)setExpanded:(BOOL)arg1  {
	 %log; 
	 RLog(@"omriku setting expanded! should HIDE all labels here.  if 1 == %d", arg1);
	 if (arg1) {
	 	timeRemainingLabel.hidden = 1;
		for(id key in moduleAndLabels) {
			CCUIContentModuleContainerView *moduleWithLabel = [moduleDictionary objectForKey:key];
			for (UIView *subView  in ((UIView*)moduleWithLabel).subviews) {
				if ([subView isKindOfClass:[UILabel class]]) {
					((UILabel*)subView).hidden = 1;
				}	
			}
		}
	 }
	 else {
		timeRemainingLabel.hidden = 0;
		for(id key in moduleAndLabels) {
			CCUIContentModuleContainerView *moduleWithLabel = [moduleDictionary objectForKey:key];
			for (UIView *subView  in ((UIView*)moduleWithLabel).subviews) {
				if ([subView isKindOfClass:[UILabel class]]) {
					((UILabel*)subView).hidden = 0;
				}	
			}
		}
	 }
	 %orig; 
}
%end

%hook SBControlCenterController
- (void)_willPresent {
	%orig;
	dismissingCC = FALSE;
}
- (void)_willDismiss {
	%orig;
	dismissingCC = TRUE;
	if (timeRemainingLabel) {
		[timeRemainingLabel removeFromSuperview];
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


%hook CCUIAppLauncherViewController
%new
-(BOOL)isAlarm{
	RLog(@"omriku checking for alarm. printng self: %@", self);
	return [((SBFApplication *)[self valueForKey:@"_application"]).applicationBundleIdentifier isEqualToString:@"com.apple.mobiletimer"];
}
//CHANGE THIS TO BE LIKE THE TIMER SHIT. HOOKING ON A VIEW WITHOUT ALL THIS SHIT. ALL SIZES ARE PROBABLY THE SAME FOR ALL IPHONES
-(void)viewDidLoad{
	%orig;
	RLog(@"omriku enters here! CCUIAppLauncherViewController print self :%@",self);
	if([self isAlarm]){
		if(!alarmLabel){
			alarmLabel = [UILabel new];
			alarmLabel.font = [alarmLabel.font fontWithSize:10];
			alarmLabel.textColor = [UIColor whiteColor];
			alarmLabel.textAlignment = NSTextAlignmentCenter;
			alarmLabel.center = CGPointMake(self.view.frame.size.width/2, 12);
			alarmLabel.frame = CGRectMake(10,52,50,10);
			struct utsname systemInfo;
  			uname(&systemInfo);
  			NSString *device = @(systemInfo.machine);
			if([device isEqualToString:@"iPhone11,8"]){
				alarmLabel.frame = CGRectMake(10,55,58,15);
			}
		}
		dispatch_async(dispatch_get_main_queue(), ^{
    		[NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer){
    			MTAlarm *nextAlarm = [[[[%c(SBScheduledAlarmObserver) sharedInstance] valueForKey:@"_alarmManager"] valueForKey:@"_cache"] valueForKey:@"_nextAlarm"];
    			if(nextAlarm){
    				NSDate *currentDate = [NSDate date];
    				NSDate *alarmDate = [nextAlarm nextFireDate];
					NSTimeInterval elapsedTime = [alarmDate timeIntervalSinceDate:currentDate];
    				div_t h = div(elapsedTime, 3600);
    				int hours = h.quot;
    				div_t m = div(h.rem, 60);
    				int minutes = m.quot;
    				int seconds = m.rem;
					alarmLabel.text = [[NSString stringWithFormat:@"%s%d:%s%d:%s%d", hours < 10 ? "0" : "", hours, minutes < 10 ? "0" : "", minutes, seconds < 10 ? "0" : "", seconds] stringByReplacingOccurrencesOfString:@"-" withString:@""];

    			}
    			else{
    				alarmLabel.text = nil;
    			}
			}];
		});
		[self.view addSubview:alarmLabel];
	}
}
%end