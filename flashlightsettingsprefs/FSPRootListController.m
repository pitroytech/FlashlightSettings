#import <Foundation/Foundation.h>
#import "FSPRootListController.h"

@implementation FSPRootListController

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
