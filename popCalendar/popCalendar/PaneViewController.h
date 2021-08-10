// PaneViewController.h

#import <Cocoa/Cocoa.h>
#import "CalMonthView.h"
#import "CalYearView.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@class PCalWindow;
@class PaneTopYearView;
@protocol PaneTopYearViewDelegateProtocol;

@interface PaneViewController : NSViewController <NSWindowDelegate,PaneTopYearViewDelegateProtocol>
{
	PCalWindow *_myWindow;
	__weak id _delegator;
	NSView *_winContView;

	int _showedSens;
	BOOL _isShowing;
	BOOL _isHidding;
	BOOL _isSwitching;

	PaneTopYearView *_topYearView;
	PaneTopYearView *_topMonthView;

	CalYearView *_calYearView;
	CalMonthView *_calMonthView;
}

@property (nonatomic,strong) IBOutlet NSView *headerView;
@property (nonatomic,strong) IBOutlet NSView *calContentView;

- (id)initWithDelegator:(id)delegator;

- (void)refreshData;

- (BOOL)isVisiblePanel;
- (BOOL)canHidePanelWindow;
- (void)showWindowAt:(NSRect)zone screen:(NSScreen*)screen isDarkStyle:(BOOL)isDarkStyle;
- (void)hideWindow:(BOOL)discrete;

- (void)switchToMode:(NSInteger)mode infos:(NSDictionary*)infos;

@end

@protocol PaneViewControllerDelegatorProtocol <NSObject>

- (void)paneViewControllerDidShow:(PaneViewController*)sender;
- (void)paneViewControllerWantsHide:(PaneViewController*)sender;
- (void)paneViewControllerDidHide:(PaneViewController*)sender;
- (void)paneViewController:(PaneViewController*)sender performAction:(NSDictionary*)action;
- (NSRect)paneViewControllerStatusItemZone:(PaneViewController*)sender;

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
