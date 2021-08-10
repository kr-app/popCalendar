// AppDelegate.h

#import <Cocoa/Cocoa.h>
#import "PaneViewController.h"
#import "TH_APP-Swift.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@interface AppDelegate : NSObject <	NSApplicationDelegate,NSMenuDelegate,
																THHotKeyCenterProtocol,
																PreferencesWindowControllerDelegatorProtocol,
																StatusIconDelegateProtocol>
{
	StatusIcon *_statusIcon;
	BOOL _hasRightMenuOpened;

	PaneViewController *_paneViewController;

	BOOL _keepVisibleOnDeactivate;
}

- (IBAction)changeViewMenu:(id)sender;

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
