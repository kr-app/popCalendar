// CalEventsViewController.h

#import <Cocoa/Cocoa.h>
#import "EventEditorViewController.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@class CalEventListView;
@interface CalEventsViewController : NSViewController <CalEventListViewDelegateProtocol,EventEditorViewControllerDelegateProtocol>
{
	__weak id _delegator;
	PCalSource *_calSource;
	PCalDate *_calDate;

	CalEventListView *_eventListView;
	EventEditorViewController *_eventEditorViewController;

	BOOL _isSomeAnimating;
}

- (PCalDate*)calDate;

- (id)initWithDelegator:(id)delegator calSource:(PCalSource*)calSource;

- (BOOL)terminateEdition:(NSWindow*)mainWindow;

- (NSSize)updateForCalDate:(PCalDate*)calDate;
- (void)currentCalDateUpdated:(PCalDate*)calDate;

//- (void)terminateByUser;

@end

@protocol CalEventsViewControllerDelegateProtocol <NSObject>
- (void)calEventsViewController:(CalEventsViewController*)sender didChange:(NSDictionary*)infos;
@end
//--------------------------------------------------------------------------------------------------------------------------------------------
