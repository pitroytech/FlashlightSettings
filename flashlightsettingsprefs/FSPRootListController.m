#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import "FSPRootListController.h"

static void PreviewHapticCallback(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo);

//	Declared so the C notification callback below can call back into the class.
@interface FSPRootListController ()
-(void)rememberHapticSettings;
-(void)previewHapticIfChanged;
@end

@implementation FSPRootListController {
	BOOL _lastHapticEnabled;
	NSString *_lastHapticStyle;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

- (void)loadView {
	[super loadView];
	((UITableView *)[self table]).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	[self reloadSpecifiers];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	//	The last shortcut rows are written by SpringBoard, so re-read them every
	//	time this page comes back into view.
	[self reloadSpecifiers];
	[self rememberHapticSettings];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self rememberHapticSettings];

	//	Every switch in this page posts the reload notification, and this
	//	process receives its own posts, so it doubles as a "settings changed"
	//	signal for the haptic preview.
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		(__bridge const void *)self,
		&PreviewHapticCallback,
		BUNDLE_NOTIFY,
		NULL,
		CFNotificationSuspensionBehaviorCoalesce
	);
}

- (void)dealloc {
	CFNotificationCenterRemoveEveryObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		(__bridge const void *)self
	);
}

-(void)rememberHapticSettings {
	NSUserDefaults *tweakPrefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	_lastHapticEnabled = [tweakPrefs boolForKey:@"kHapticFeedback"];
	_lastHapticStyle = [tweakPrefs stringForKey:@"kHapticStyle"] ?: @"medium";
}

//	Plays the feedback the user just picked, so the strength can be compared
//	without leaving Settings and pressing a hardware button.
-(void)previewHapticIfChanged {
	NSUserDefaults *tweakPrefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	BOOL nowEnabled = [tweakPrefs boolForKey:@"kHapticFeedback"];
	NSString *nowStyle = [tweakPrefs stringForKey:@"kHapticStyle"] ?: @"medium";

	BOOL turnedOn = nowEnabled && !_lastHapticEnabled;
	BOOL styleChanged = nowEnabled && ![nowStyle isEqualToString:_lastHapticStyle];

	_lastHapticEnabled = nowEnabled;
	_lastHapticStyle = nowStyle;

	if (!turnedOn && !styleChanged)
		return;

	SystemSoundID soundID = 1520;
	if ([nowStyle isEqualToString:@"light"])
		soundID = 1519;
	else if ([nowStyle isEqualToString:@"heavy"])
		soundID = 1521;

	AudioServicesPlaySystemSound(soundID);
}


-(id)tweakPreferenceForKey:(NSString *)key {
	NSUserDefaults *tweakPrefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
	return [tweakPrefs objectForKey:key];
}

-(id)lastTriggerSource:(PSSpecifier *)specifier {
	id value = [self tweakPreferenceForKey:@"kLastTriggerSource"];
	if (![value isKindOfClass:[NSString class]])
		return @"Never fired";

	//	Show the same wording the shortcut list uses.
	NSDictionary *names = @{
		@"volume": @"Volume Up + Down",
		@"doubleLock": @"Lock Double Click",
		@"tripleLock": @"Lock Triple Click",
		@"holdLock": @"Lock Hold",
		@"doubleHome": @"Home Double Click",
		@"tripleHome": @"Home Triple Click",
		@"holdHome": @"Home Hold",
		@"ringer": @"Ringer",
	};
	return names[value] ?: value;
}

-(id)lastTriggerDate:(PSSpecifier *)specifier {
	id value = [self tweakPreferenceForKey:@"kLastTriggerDate"];
	if (![value isKindOfClass:[NSDate class]])
		return @"—";

	return [NSDateFormatter localizedStringFromDate:value
										  dateStyle:NSDateFormatterShortStyle
										  timeStyle:NSDateFormatterMediumStyle];
}

-(id)recentWakeSources:(PSSpecifier *)specifier {
	id value = [self tweakPreferenceForKey:@"kRecentBacklightSources"];
	if (![value isKindOfClass:[NSArray class]] || [value count] == 0)
		return @"—";

	return [value componentsJoinedByString:@", "];
}

-(id)lastTriggerScreenOn:(PSSpecifier *)specifier {
	id value = [self tweakPreferenceForKey:@"kLastTriggerScreenOn"];
	if (![value isKindOfClass:[NSNumber class]])
		return @"—";

	return [value boolValue] ? @"Yes" : @"No";
}

-(void)OpenGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://github.com/wrp1002/FlashlightSettings"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenPaypal {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://paypal.me/wrp1002"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenReddit {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://reddit.com/u/wes_hamster"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenEmail {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"mailto:wes.hamster@gmail.com?subject=FlashlightSettings"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)Reset {
	NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];

	NSArray *allKeys = [prefs dictionaryRepresentation].allKeys;

	for (NSString *key in allKeys) {
		[prefs removeObjectForKey:key];
	}
	[prefs synchronize];

	[self reloadSpecifiers];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), BUNDLE_NOTIFY, nil, nil, true);
}

-(void)Respring {
	// From Cephei since other methods I tried didn't work
	[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/FrontBoardServices.framework"] load];
	[[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SpringBoardServices.framework"] load];

	Class $FBSSystemService = NSClassFromString(@"FBSSystemService");
	Class $SBSRelaunchAction = NSClassFromString(@"SBSRelaunchAction");
	if ($FBSSystemService && $SBSRelaunchAction) {
		SBSRelaunchAction *restartAction = [$SBSRelaunchAction actionWithReason:@"RestartRenderServer" options:SBSRelaunchActionOptionsFadeToBlackTransition targetURL:nil];
		[[$FBSSystemService sharedService] sendActions:[NSSet setWithObject:restartAction] withResult:nil];
	}
}


@end


static void PreviewHapticCallback(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
	FSPRootListController *controller = (__bridge FSPRootListController *)observer;
	[controller previewHapticIfChanged];
}
