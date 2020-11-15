#include "CCCRootListController.h"
#import <spawn.h>
#include <RemoteLog.h>

#define GENERAL_PREFS @"/var/mobile/Library/Preferences/com.0xkuj.cccountersprefs.plist"
#define MODULE_LABELS_PATH @"/var/mobile/Library/Preferences/com.0xkuj.cccounters_modules.plist"

@implementation CCCRootListController

/* load all specifiers from plist file */
- (NSMutableArray*)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
		[self applyModificationsToSpecifiers:(NSMutableArray*)_specifiers];
	}

	return (NSMutableArray*)_specifiers;
}

/* save a copy of those specifications so we can retrieve them later */
- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers
{
	_allSpecifiers = [specifiers copy];
	[self removeDisabledGroups:specifiers];
}

/* actually remove them when disabled */
- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
{
	for(PSSpecifier* specifier in [specifiers reverseObjectEnumerator])
	{
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)
		{
			BOOL enabled = [[self readPreferenceValue:specifier] boolValue];
			if(!enabled)
			{
				NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange([_allSpecifiers indexOfObject:specifier]+1, [nestedEntryCount intValue])] mutableCopy];

				BOOL containsNestedEntries = NO;

				for(PSSpecifier* nestedEntry in nestedEntries)	{
					NSNumber* nestedNestedEntryCount = [[nestedEntry properties] objectForKey:@"nestedEntryCount"];
					if(nestedNestedEntryCount)	{
						containsNestedEntries = YES;
						break;
					}
				}

				if(containsNestedEntries)	{
					[self removeDisabledGroups:nestedEntries];
				}

				[specifiers removeObjectsInArray:nestedEntries];
			}
		}
	}
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

// cannot be only apps & only lockscreen, so disable the other when on is enabled
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
	//causes the color to fallback, canceled for now
	//[super setPreferenceValue:value specifier:specifier];

	if(specifier.cellType == PSSwitchCell)	{
		NSNumber* numValue = (NSNumber*)value;
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)	{
			NSInteger index = [_allSpecifiers indexOfObject:specifier];
			NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange(index + 1, [nestedEntryCount intValue])] mutableCopy];
			[self removeDisabledGroups:nestedEntries];

			if([numValue boolValue])  {
				[self insertContiguousSpecifiers:nestedEntries afterSpecifier:specifier animated:YES];
			}
			else  {
				[self removeContiguousSpecifiers:nestedEntries animated:YES];
			}
		}
	}
}

/* default settings and repsring right after. files to be deleted are specified in this function */
-(void)defaultsettings:(PSSpecifier*)specifier {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
    									                    message:@"This will restore CCCounters Settings to default\nAre you sure?" 
    														preferredStyle:UIAlertControllerStyleAlert];
	/* prepare function for "yes" button */
	UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
    		handler:^(UIAlertAction * action) {
				[[NSFileManager defaultManager] removeItemAtURL: [NSURL fileURLWithPath:GENERAL_PREFS] error: nil];
				[[NSFileManager defaultManager] removeItemAtURL: [NSURL fileURLWithPath:MODULE_LABELS_PATH] error: nil];
    			[self reload];
    			CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    			CFNotificationCenterPostNotification(r, (CFStringRef)@"com.0xkuj.cccountersprefs.settingschanged", NULL, NULL, true);
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice"
				message:@"Settings restored to default\nPlease respring your device" 
				preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction* DoneAction =  [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault
    			handler:^(UIAlertAction * action) {
					pid_t pid;
					const char* args[] = {"killall", "backboardd", NULL};
					posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
				}];
				[alert addAction:DoneAction];
				[self presentViewController:alert animated:YES completion:nil];
	}];
	/* prepare function for "no" button" */
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { return; }];
	/* actually assign those actions to the buttons */
	[alertController addAction:OKAction];
    [alertController addAction:cancelAction];
	/* present the dialog and wait for an answer */
	[self presentViewController:alertController animated:YES completion:nil];
	return;
}

- (void)respring:(id)sender {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Respring"
    									                    message:@"Are you sure?" 
    														preferredStyle:UIAlertControllerStyleAlert];
	/* prepare function for "yes" button */
	UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
    		handler:^(UIAlertAction * action) {
			pid_t pid;
			const char* args[] = {"killall", "backboardd", NULL};
			posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	}];
	/* prepare function for "no" button" */
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { return; }];
	/* actually assign those actions to the buttons */
	[alertController addAction:OKAction];
    [alertController addAction:cancelAction];
	/* present the dialog and wait for an answer */
	[self presentViewController:alertController animated:YES completion:nil];
}

/* iOS 13 deprecated these functions */

-(void)openTwitter {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.twitter.com/omrkujman"]];
}

-(void)donationLink {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/0xkuj"]];
}

#if 0
-(void)openTwitter {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://www.twitter.com/omrkujman"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

-(void)donationLink {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://www.paypal.me/0xkuj"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}
#endif
@end
