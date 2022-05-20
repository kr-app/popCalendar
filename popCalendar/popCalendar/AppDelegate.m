// AppDelegate.m

#import "AppDelegate.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
	THLogInfo(@"config:%@", [THRunningApp config]);

//#ifdef DEBUG
//#ifdef TH_MAS
//	THException([THRunningApp isSandboxedApp]==NO,@"isSandboxedApp==NO");
//#else
//	THException([THRunningApp isSandboxedApp]==YES,@"isSandboxedApp==YES");
//#endif
//#endif

	[THRunningApp killOtherApps:nil];

#ifndef TH_MAS
//	[[THCheckForUpdates shared] setAppBuild:[THFunctions appBuild].integerValue infoURL:TH_WebSiteURL("popcalendar.version",1)];
#endif

	_statusIcon=[[StatusIcon alloc] init];
	[_statusIcon setIconStyle];

	[[THHotKeyCenter shared] registerHotKeyRepresentation:[THHotKeyRepresentation hotKeyRepresentationFromUserDefaultsWithTag:1]];

	if ([THStatusIconAlfredFirst needsDisplayAlfredFirst]==YES)
		[self performSelector:@selector(showAlfredFirstDelayed) withObject:nil afterDelay:0.5];
}

- (void)applicationWillBecomeActive:(NSNotification*)notification
{
//	[_statusItemView updateIsDarkMode];
}

- (void)applicationWillTerminate:(NSNotification*)notification
{
	[[PCalUserContext shared] synchronize];
}

- (void)applicationWillResignActive:(NSNotification*)notification
{
	if ([self paneWindowIsVisible]==YES)
		[self hidePaneWindowAuto];
}

#pragma mark -

- (void)showAlfredFirstDelayed
{
	[THStatusIconAlfredFirst setNeedsDisplayAlfredFirst:NO];

	NSWindow *statusItemWindow=_statusIcon.statusItemWindow;
	THException(statusItemWindow==nil,@"statusItemWindow==nil");

	NSRect siwRect=statusItemWindow.frame;
	NSScreen *screen=statusItemWindow.screen;
	if (screen==nil)
		screen=[NSScreen mainScreen];

	CGFloat pt=CGFloatFloor(siwRect.origin.x+(siwRect.size.width/2.0));
	[THStatusIconAlfredFirst showAtPosition:pt onScreen:screen];
}

#pragma mark -

- (void)statusIcon:(StatusIcon*)sender pressed:(NSDictionary*)info
{
	[THStatusIconAlfredFirst hide];
	//[THOSAppearance updateDarkMode];

	if ([info[@"doubleClick"] boolValue]==YES)
	{
		if ([self paneWindowIsVisible]==YES)
			[self hidePaneWindow:YES discrete:NO];
		[PCalUserInterration openCalendarApp:NULL];
		return;
	}
	else if ([info[@"isRight"] boolValue]==YES)
	{
		if ([self paneWindowIsVisible]==YES)
			[self hidePaneWindow:YES discrete:YES];
		return;
	}

	if ([self paneWindowIsVisible]==YES)
		[self hidePaneWindow:YES discrete:NO];
	else
	{
		[[THFrontmostAppSaver shared] save];
		[self showPaneWindow:YES];
	}
}

#pragma mark -

- (BOOL)paneWindowIsVisible
{
	return (_paneViewController!=nil && _paneViewController.isVisiblePanel==YES)?YES:NO;
}

- (void)showPaneWindow:(BOOL)isAnimated
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[_statusIcon setIsPressed:YES];

//#ifdef TH_MAS
//	if ([THReviewReclam displayReclamIfNecessaryProductId:@"popcalendar/id645427315" storeKind:1]==1)
//		return;
//#else
//	[[THCheckForUpdates shared] synchronizeIfNecessary];
//
//	if ([THReviewReclam displayReclamIfNecessaryProductId:@"47965/popcalendar" storeKind:2]==1)
//		return;
//#endif

	NSWindow *statusItemWindow=_statusIcon.statusItemWindow;
	THException(statusItemWindow==nil,@"statusItemWindow==nil");

	NSRect swFrame=statusItemWindow.frame;

	NSScreen *screen=statusItemWindow.screen;
	if (screen==nil)
	{
		THLogError(@"siWindow.screen==nil statusItemWindow:%@",statusItemWindow);
		screen=[NSScreen mainScreen];
	}

	swFrame.origin.x-=screen.frame.origin.x;
	swFrame.origin.y-=screen.frame.origin.y;

	CGFloat menuBarHeight=[NSApplication sharedApplication].mainMenu.menuBarHeight;
	swFrame.origin.y=screen.frame.size.height-(menuBarHeight>0.0?menuBarHeight:22.0);

	BOOL isDarkStyle=NO;//[THOSAppearance isDarkMode];
	if (isDarkStyle==NO)
		swFrame.origin.y-=1.0;

	//NSLog(@"screen:%@ isMainScreen:%d swPt:%@",screen,[NSScreen mainScreen]==screen?1:0,NSStringFromPoint(swPt));
	if (_paneViewController==nil)
		_paneViewController=[[PaneViewController alloc] initWithDelegator:self];

	NSRect zone=NSMakeRect(CGFloatFloor(swFrame.origin.x),CGFloatFloor(swFrame.origin.y),CGFloatFloor(swFrame.size.width),0.0);
	[_paneViewController showWindowAt:zone screen:screen isDarkStyle:isDarkStyle];
}

- (void)hidePaneWindow:(BOOL)isAnimated discrete:(BOOL)discrete
{
	if ([_paneViewController canHidePanelWindow]==NO)
		return;
	if (discrete==NO)
		[_statusIcon setIsPressed:NO];
	[_paneViewController hideWindow:discrete];
}

- (void)hidePaneWindowAuto
{
	if (_keepVisibleOnDeactivate==YES)
		return;
	[self hidePaneWindow:YES discrete:NO];
}

#pragma mark -

- (void)paneViewControllerWantsHide:(PaneViewController*)sender
{
	[self hidePaneWindowAuto];
}

- (void)paneViewControllerDidShow:(PaneViewController*)sender
{
	[_statusIcon setIsPressed:YES];

	static int isNotified=0;
	if (isNotified==0 && [[PCalSource shared] hasUserRights]==NO)
	{
		isNotified=1;

		static int isRequested=0;
		if (isRequested==0)
		{
			isRequested=1;
			[[PCalSource shared] requestUserRights];
			return;
		}

		NSString *title=THLocalizedStringFormat(@"%@ does not have access to your calendars.",[THRunningApp appName]);
		NSString *msg=THLocalizedString(@"Calendars access is used to view and edit your calendar events.\n\nTo allow access, go to System Preferences > Security & Privacy > Privacy.");
		NSArray *buttons=@[THLocalizedString(@"Ok"),THLocalizedString(@"Open Security Preferences")];
		NSAlert *alert=[[NSAlert alloc] initWithTitle:title message:msg buttons:buttons];

		[alert beginSheetModalForWindow:sender.view.window completionHandler:^(NSModalResponse response)
		{
			if (response==NSAlertSecondButtonReturn)
			{
				NSString *accountPane=@"/System/Library/PreferencePanes/Security.prefPane";
				if ([[NSFileManager defaultManager] fileExistsAtPath:accountPane]==YES)
					[[NSWorkspace sharedWorkspace] openFile:accountPane];
			}
		}];
	}
}

- (void)paneViewControllerDidHide:(PaneViewController*)sender
{
	_keepVisibleOnDeactivate=NO;
	[_statusIcon setIsPressed:NO];
	[[THFrontmostAppSaver shared] restore];
}

- (void)paneViewController:(PaneViewController*)sender performAction:(NSDictionary*)actionInfo
{
	if ([actionInfo[@"kind"] integerValue]==1)
	{
		[self hidePaneWindowAuto];
		PCalDate *date=actionInfo[@"date"];
		[PCalUserInterration showDateInCalendarApp:date.date];
	}
	else if ([actionInfo[@"kind"] integerValue]==2)
	{
		[self hidePaneWindowAuto];
		PCalEvent *calEvent=actionInfo[@"calEvent"];
		[[PCalUserInterration shared] revealEventInCalendarApp:calEvent.event];
	}
}

- (NSRect)paneViewControllerStatusItemZone:(PaneViewController*)sender
{
	NSWindow *siWindow=_statusIcon.statusItemWindow;
	THException(siWindow==nil,@"siWindow==nil");

	NSRect swFrame=siWindow.frame;

	NSScreen *screen=siWindow.screen;
	if (screen==nil)
	{
		THLogError(@"siWindow.screen==nil siWindow:%@",siWindow);
		screen=[NSScreen mainScreen];
	}

	swFrame.origin.x-=screen.frame.origin.x;
	swFrame.origin.y-=screen.frame.origin.y;

	CGFloat menuBarHeight=[NSApplication sharedApplication].mainMenu.menuBarHeight;
	swFrame.origin.y=screen.frame.size.height-(menuBarHeight>0.0?menuBarHeight:22.0);

	BOOL isDarkStyle=NO;//[THOSAppearance isDarkMode];
	if (isDarkStyle==NO)
		swFrame.origin.y-=1.0;

	return NSMakeRect(CGFloatFloor(swFrame.origin.x),CGFloatFloor(swFrame.origin.y),CGFloatFloor(swFrame.size.width),0.0);
}

#pragma mark -

- (void)preferencesWindowController:(PreferencesWindowController*)sender didChange:(NSDictionary*)changeInfos
{
	if ([changeInfos[@"kind"] integerValue]==1)
		[_paneViewController refreshData];
	else if ([changeInfos[@"kind"] integerValue]==2)
		[_statusIcon setIconStyle];
}

#pragma mark -

- (void)hotKeyCenter:(THHotKeyCenter*)sender pressedHotKey:(NSDictionary*)tag
{
	[self statusIcon:_statusIcon pressed:nil];
}

#pragma mark -

- (IBAction)changeViewMenu:(NSMenuItem*)sender
{
	NSInteger mode=sender.tag==2?PCalViewModeByMonth:PCalViewModeByYear;
	[_paneViewController switchToMode:mode infos:nil];
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
