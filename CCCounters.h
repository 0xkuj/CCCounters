#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <rootless.h>

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
@property (nonatomic,readonly) id<MTTimerManagerIntentSupport> timerManager; 
-(id)currentTimer;
-(id)updateTimer:(id)arg1 ;
@end

@interface MTTimerManagerExportedObject
@property (nonatomic,readonly) MTTimerManager * timerManager;
@end

@interface NAFuture {
	id _resultValue;
}
@end

@interface CCUIContentModuleContainerViewController
@property (nonatomic,copy) NSString * moduleIdentifier;
-(BOOL)isExpanded;
-(void)hideLabel:(BOOL)hide;
@end

static BOOL dismissingCC = FALSE,timerExpanded = FALSE;
BOOL isEnabled,isAlarmETA,isTimerETA,isLastPressed,isStyleAlarmColorRand,isStyleTimerColorRand,isStyleLastPressedColorRand;
UIColor *styleAlarmColor = nil, *styleTimerColor = nil, *styleLastPressedColor = nil;
UILabel *timeRemainingLabel,*alarmRemainingLabel;
NSDate *pendingDateTimer,*pendingDateAlarm;
CCUIContentModuleContainerView *timerModuleContainerView;
NSTimer *pendingTimer,*pendingTimerAlarm;
static int singleInit = 0;
NSMutableDictionary* moduleAndLabels;
NSDictionary *moduleDictionary;
MTTimerManager* globalTimerMgr;

