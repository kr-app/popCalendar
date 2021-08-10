// CalEventsViewController.m

#import "CalEventsViewController.h"
#import "TH_APP-Swift.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@interface CalEventsBgView : NSView
@end

@implementation CalEventsBgView

//- (void)drawRect:(NSRect)dirtyRect
//{
//	[[NSColor orangeColor] th_drawInRect:self.bounds];
//}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation CalEventsViewController

- (PCalDate*)calDate { return _calDate; }

- (id)initWithDelegator:(id)delegator calSource:(PCalSource*)calSource
{
	if (self=[super initWithNibName:[self className] bundle:nil])
	{
		_delegator=delegator;
		_calSource=calSource;
	}
	return self;
}

- (BOOL)terminateEdition:(NSWindow*)mainWindow
{
	if (_eventEditorViewController!=nil && [_eventEditorViewController terminateEdition:mainWindow completion:NULL]==NO)
		return NO;
	return YES;
}

- (NSSize)updateRendezVousViewWithDate:(PCalDate*)date selectedEvent:(PCalEvent*)selectedEvent
{
	[_eventListView updateWithCalDate:date events:date.events selectedEvent:selectedEvent.eventIdentifier];
	NSSize contentSize=[_eventListView contentSizeWithOptions:1];
	_eventListView.frame=NSMakeRect(0.0,1.0,self.view.frame.size.width,contentSize.height);
	return NSMakeSize(contentSize.width,contentSize.height+1.0*2.0);
}

- (NSSize)updateForCalDate:(PCalDate*)calDate
{
	THException(calDate==nil,@"calDate==nil");

	if (_eventEditorViewController!=nil)
	{
//		if (_isSomeAnimating==NO)
//			[_calSource cancelChangesOfCalEvent:_eventEditorViewController.calEvent];

		[_eventListView setHidden:NO];
		_eventListView.alphaValue=1.0;

		[_eventEditorViewController.view removeFromSuperview];
		_eventEditorViewController=nil;
	}

	_calDate=calDate;
	NSSize frameSz=self.view.frame.size;

	if (_eventListView==nil)
	{
		_eventListView=[[CalEventListView alloc] initWithFrame:NSMakeRect(0.0,0.0,frameSz.width,100.0)];
		_eventListView.autoresizingMask=NSViewWidthSizable|NSViewMaxYMargin;
		_eventListView.delegator=self;
		_eventListView.showNoSelection=YES;
		[self.view addSubview:_eventListView];
	}

	return [self updateRendezVousViewWithDate:calDate selectedEvent:nil];
}

- (void)currentCalDateUpdated:(PCalDate*)calDate
{
	THException(calDate==nil,@"calDate==nil");
	_calDate=calDate;
}

- (void)showEditorForEvent:(PCalEvent*)calEvent
{
	[self showEditorForCalEvent:calEvent animated:YES];

	NSDictionary *nInfos=@{@"kind":@(1),@"size":[NSValue valueWithSize:_eventEditorViewController.view.frame.size]};
	[_delegator calEventsViewController:self didChange:nInfos];
}

- (void)showEditorForCalEvent:(PCalEvent*)calEvent animated:(BOOL)animated
{
	if (_isSomeAnimating==YES || _eventListView==nil || _eventEditorViewController!=nil || calEvent==nil)
		return;

	_eventEditorViewController=[[EventEditorViewController alloc] initWithDelegator:self];
	//[_eventEditorViewController setAlwaysCancelButton:YES];
	_eventEditorViewController.view.alphaValue=0.0;

	NSRect rvView=_eventEditorViewController.view.frame;
	rvView.origin=NSMakePoint(0.0,CGFloatFloor(self.view.frame.size.height-rvView.size.height));
	rvView.size.width=self.view.frame.size.width;
	_eventEditorViewController.view.frame=rvView;

	[self.view addSubview:_eventEditorViewController.view];
	//NSArray *sourcesCalendars=[_calSource sourcesCalendarsWithOptions:PCalSourceCalendarListOptionNoExcluded];
	[_eventEditorViewController updateUIWithCalDate:_calDate calEvent:calEvent calSource:_calSource];

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
	{
		context.duration=0.0;
		_isSomeAnimating=YES;
		[_eventListView setAlphaValue:0.0 withAnimator:YES];
		[_eventEditorViewController.view setAlphaValue:1.0 withAnimator:YES];
	}
	completionHandler:^
	{
		_isSomeAnimating=NO;
		[_eventListView setHidden:YES];
	}];
}

- (void)hideEditorOfCalEvent:(PCalEvent*)calEvent animated:(BOOL)animated
{
	if (_isSomeAnimating==YES || _eventEditorViewController==nil)
		return;

	_eventListView.alphaValue=0.0;
	[_eventListView setHidden:NO];

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
	{
		context.duration=0.0;
		_isSomeAnimating=YES;
		[_eventListView setAlphaValue:1.0 withAnimator:YES];
		[_eventEditorViewController.view setAlphaValue:0.0 withAnimator:YES];
	}
	completionHandler:^
	{
		_isSomeAnimating=NO;
		[_eventEditorViewController.view removeFromSuperview];
		_eventEditorViewController=nil;
	}];
}

//- (void)terminateByUser
//{
//	if (_isSomeAnimating==YES || _eventEditorViewController==nil)
//		return;
//	[_calSource cancelChangesOfCalEvent:_eventEditorViewController.calEvent];
//}

#pragma mark -

- (BOOL)calEventListViewShouldChangeSelection:(CalEventListView*)sender
{
	if (_isSomeAnimating==YES)
		return NO;
	return YES;
}

- (void)calEventListView:(CalEventListView*)sender didSelectCalEvent:(PCalEvent*)calEvent
{
	if (sender.isDoubleClick==NO)
		return;
	[self showEditorForEvent:calEvent];
}

- (void)calEventListView:(CalEventListView*)sender wantsNewCalEvent:(NSDictionary*)infos
{
	if (_isSomeAnimating==YES)
		return;

	PCalEvent *calEvent=[PCalUserInterration performCreateEventForDate:sender.calDate calSource:_calSource window:[(NSView*)_delegator window]];
	if (calEvent==nil)
		return;

	[self showEditorForEvent:calEvent];
}

- (void)calEventListView:(CalEventListView*)sender revealCalEventInCalApp:(PCalEvent*)calEvent
{
	if (_isSomeAnimating==YES || calEvent==nil)
		return;
	NSDictionary *infos=@{@"kind":@(3),@"calEvent":calEvent};
	[_delegator calEventsViewController:self didChange:infos];
}

- (void)calEventListView:(CalEventListView*)sender deleteCalEvent:(PCalEvent*)calEvent
{
	if (_isSomeAnimating==YES)
		return;

	NSString *error=[_calSource removeCalEvent:calEvent];
	if (error!=nil)
		return;

	[_delegator calEventsViewController:self didChange:@{@"kind":@(2),@"calDate":_calDate}];

	NSSize contentSize=[self updateRendezVousViewWithDate:_calDate selectedEvent:nil];

	NSDictionary *infos=@{@"kind":@(1),@"size":[NSValue valueWithSize:contentSize]};
	[_delegator calEventsViewController:self didChange:infos];
}

#pragma mark -

- (BOOL)eventEditorViewController:(EventEditorViewController*)sender terminateEdition:(NSString*)action errorInfo:(NSDictionary**)pErrorInfo
{
	if (_isSomeAnimating==YES)
		return NO;

//	PCalDate *calDate=sender.calDate;
	PCalEvent *calEvent=sender.calEvent;

	NSString *error=nil;

	if ([action isEqualToString:@"delete"]==YES)
	{
		//[sender.loadingIndicator startAnimation:nil];
		error=[_calSource removeCalEvent:calEvent];
		[_delegator calEventsViewController:self didChange:@{@"kind":@(2),@"calDate":_calDate}];
		//[sender.loadingIndicator stopAnimation:nil];
	}
	else if ([action isEqualToString:@"save"]==YES)
	{
		//[sender.loadingIndicator startAnimation:nil];
		error=[_calSource saveChangesOfCalEvent:calEvent];
		[_delegator calEventsViewController:self didChange:@{@"kind":@(2),@"calDate":_calDate}];
		//[sender.loadingIndicator stopAnimation:nil];
	}
	else
	{
		[calEvent cancelChanges];
	}

	if (error!=nil)
	{
		if ([action isEqualToString:@"delete"]==YES)
			(*pErrorInfo)=[NSDictionary dictionaryWithObjectsAndKeys:THLocalizedString(@"Can not delete event."),@"title",error,@"error",nil];
		else if ([action isEqualToString:@"save"]==YES)
			(*pErrorInfo)=[NSDictionary dictionaryWithObjectsAndKeys:THLocalizedString(@"Can not save event."),@"title",error,@"error",nil];
		return NO;
	}

	[self hideEditorOfCalEvent:calEvent animated:YES];

//	PCalEvent *selectedEvent=[action isEqualToString:@"delete"]==YES?nil:calEvent;
	NSSize contentSize=[self updateRendezVousViewWithDate:_calDate selectedEvent:nil];

	NSDictionary *infos=@{@"kind":@(1),@"size":[NSValue valueWithSize:contentSize]};
	[_delegator calEventsViewController:self didChange:infos];

	return YES;
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
