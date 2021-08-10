// CalMonthView.h

#import <Cocoa/Cocoa.h>
#import "CalWeekMonthView.h"
#import "EventEditorViewController.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@class CalEventListView;

@interface CalMonthView : NSView <EventEditorViewControllerDelegateProtocol>
{
	__weak id _delegate;
	__weak PCalSource *_calSource;

	BOOL _isSwitchingMode;
	PCalWeekDayView *_weekDayView;
	PCalWeekNumberView *_calWeekWeekDayLabelView;
	CalWeekMonthView *_pageMonthViews[3];
	CalEventListView *_eventListView;
	EventEditorViewController *_eventEditorViewController;

	BOOL _isAnimating;

	NSPoint _downPoint;
	BOOL  _isDragging;
//	CGFloat _scrollDelta;
}

- (id)initWithFrame:(NSRect)frame delegate:(id)delegate;

- (NSSize)contentSize;
- (void)reloadData;
- (BOOL)terminateEdition;
- (void)willTerminateUI;
- (void)setIsSwitchingMode:(BOOL)isSwitchingMode;

- (void)switchToYear:(NSInteger)year month:(NSInteger)month;
- (void)performUserRequest:(NSString*)request infos:(NSDictionary*)infos;

@end

@protocol CalMonthViewDelegateProtocol <NSObject>
@required
- (void)calMonthView:(CalMonthView*)monthView doAction:(NSDictionary*)action;
@end
//--------------------------------------------------------------------------------------------------------------------------------------------
