//
//  OBAppDelegate.m
//  Klay
//
//  Created by Ondra Beneš on 3/2/13.
//  Copyright (c) 2013 Ondra Beneš. All rights reserved.
//

#import "OBAppDelegate.h"
#import <Carbon/Carbon.h>

@interface OBAppDelegate ()

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, readonly) NSURL *appURL;

- (BOOL)willStartAtLogin:(NSURL *)itemURL;

@end

@implementation OBAppDelegate

- (NSURL *)appURL {
	return [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)startAtLogin {
	return [self willStartAtLogin:self.appURL];
}

- (void)setStartAtLogin:(BOOL)startAtLogin {
	[self willChangeValueForKey:@"startAtLogin"];
	[self setStartAtLogin:self.appURL enabled:startAtLogin];
	[self didChangeValueForKey:@"startAtLogin"];
}

#pragma mark - Methods
- (void)setStartAtLogin:(NSURL *)itemURL enabled:(BOOL)enabled {
	LSSharedFileListItemRef existingItem = NULL;
	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		UInt32 seed = 0U;
		NSArray *currentLoginItems = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItems, &seed);
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
			
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				Boolean foundIt = CFEqual(URL, (__bridge CFURLRef)itemURL);
				CFRelease(URL);
				
				if (foundIt) {
					existingItem = item;
					break;
				}
			}
		}
		
		if (enabled && (existingItem == NULL)) {
			LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
										  NULL, NULL, (__bridge CFURLRef)itemURL, NULL, NULL);
			
		} else if (!enabled && (existingItem != NULL))
			LSSharedFileListItemRemove(loginItems, existingItem);
		
		CFRelease(loginItems);
	}
}

- (BOOL)willStartAtLogin:(NSURL *)itemURL {
	Boolean foundIt=false;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		UInt32 seed = 0U;
		NSArray *currentLoginItems = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItems, &seed);
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
			
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				foundIt = CFEqual(URL, (__bridge CFURLRef)itemURL);
				CFRelease(URL);
				
				if (foundIt)
					break;
			}
		}
		CFRelease(loginItems);
	}
	return (BOOL)foundIt;
}

#pragma mark - App lifecycle
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardInputSourceDidChange:) name:@"AppleSelectedInputSourcesChangedNotification" object:nil];
	
	_statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	_statusItem.menu = self.statusMenu;
	NSImage *statusIcon = [NSImage imageNamed:@"StatusIcon"];
	[statusIcon setTemplate:YES];
	_statusItem.image = statusIcon;
	_statusItem.highlightMode = YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Actions
- (IBAction)quitApp:(id)sender {
	[[NSApplication sharedApplication] terminate:sender];
}

#pragma mark - Notifications
- (void)keyboardInputSourceDidChange:(NSNotification *)notification {
	TISInputSourceRef inputSource = TISCopyCurrentKeyboardInputSource();
	NSString *inputSourceLocalizedName = [( __bridge NSString * )TISGetInputSourceProperty( inputSource, kTISPropertyLocalizedName ) copy];
	CFRelease( inputSource );
	
	NSUserNotification *userNotification = [[NSUserNotification alloc] init];
	userNotification.title = NSLocalizedString( @"Keyboard Input Source Changed", nil );
	userNotification.subtitle = [NSString stringWithFormat:@"%@ - new layout", inputSourceLocalizedName];
	userNotification.hasActionButton = NO;
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:userNotification];
}

@end
