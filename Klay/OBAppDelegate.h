//
//  OBAppDelegate.h
//  Klay
//
//  Created by Ondra Beneš on 3/2/13.
//  Copyright (c) 2013 Ondra Beneš. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OBAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) IBOutlet NSMenu *statusMenu;
@property (nonatomic) BOOL startAtLogin;

- (IBAction)quitApp:(id)sender;
@end
