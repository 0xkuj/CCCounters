#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface CCCRootListController : PSListController {
    NSMutableArray* _allSpecifiers;
}

//- (void)HeaderCell;
- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers;
- (void)defaultsettings:(PSSpecifier*)specifier ;
- (void)openTwitter;
- (void)donationLink;

@end
