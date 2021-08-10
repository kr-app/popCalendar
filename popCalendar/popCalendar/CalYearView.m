// CalYearView.m

#import "CalYearView.h"
#import "CalYearMonthView.h"
#import "CalEventsViewController.h"

//---------------------------------------------------------------------------------------------------------------------------------------------
@implementation CalYearView

+ (NSSize)contentSize
{
	return NSMakeSize(444,588.0);
}

- (id)initWithFrame:(NSRect)frameRect delegate:(id)delegate
{
	if (self=[super initWithFrame:frameRect])
	{
		self.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
		_delegate=delegate;
		_calSource=[PCalSource shared];
	}
	return self;
}

#pragma mark -

- (BOOL)acceptsFirstResponder { return YES; }

- (BOOL)canBecomeKeyView { return YES; }

#pragma mark -

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	[self generate_trackingArea];
}

- (void)generate_trackingArea
{
	if (_trackingArea!=nil)
		[self removeTrackingArea:_trackingArea];

	NSTrackingAreaOptions options=NSTrackingMouseMoved|NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp;
	_trackingArea=[[NSTrackingArea alloc] initWithRect:self.bounds options:options owner:self userInfo:nil];

	[self addTrackingArea:_trackingArea];
}

- (void)mouseMoved:(NSEvent*)event
{
	NSPoint point=[self convertPoint:event.locationInWindow fromView:nil];
	for (CalYearMonthView *mv in _monthViews)
	{
		[mv setHeaderHighlighted:NO];
		if (NSPointInRect(point,mv.frame)==YES)
			[mv updateForMouveMoved:[mv convertPoint:event.locationInWindow fromView:nil]];
	}
}

- (void)mouseEntered:(NSEvent*)event
{
	for (CalYearMonthView *mv in _monthViews)
		[mv setHeaderHighlighted:NO];
}

- (void)mouseExited:(NSEvent*)event
{
	for (CalYearMonthView *mv in _monthViews)
		[mv setHeaderHighlighted:NO];
}

#pragma mark -

- (void)reloadData
{
	if (_myPopover!=nil && _myPopover.isShown==YES)
		[_myPopover performClose:nil];

	if (_year==nil)
	{
		NSInteger year=[PCalUserContext shared].selectedYear;
		_year=[[PCalYear alloc] initWithSource:_calSource year:year delegate:self];
	}

	[_year updateData];
	[_year updateEventsInBackground:YES];

	if (_monthViews==nil)
	{
		NSSize frameSz=self.frame.size;
		CGFloat marginLR=4.0;
		CGFloat marginTB=5.0;

		NSRect cadreRect=NSMakeRect(marginLR,0.0,frameSz.width-marginLR*2.0,frameSz.height-marginTB*2.0);
		NSSize monthSz=NSMakeSize(CGFloatFloor(cadreRect.size.width/3.0),CGFloatFloor(cadreRect.size.height/4.0));
	
		NSSize rest=NSMakeSize(	CGFloatFloor((cadreRect.size.width-monthSz.width*3.0)/2.0),
													CGFloatFloor((cadreRect.size.height-monthSz.height*4.0)/2.0));
		
		NSPoint pt=NSMakePoint(	cadreRect.origin.x+rest.width,
													cadreRect.size.height-rest.height-monthSz.height+marginTB);

		NSMutableArray *monthViews=[NSMutableArray array];

		for (PCalMonth *month in _year.months)
		{
			NSRect mvRect=NSMakeRect(pt.x+rest.width,pt.y,monthSz.width,monthSz.height);
			CalYearMonthView *monthView=[[CalYearMonthView alloc] initWithFrame:mvRect month:month delegate:self];
			[self addSubview:monthView];
			[monthViews addObject:monthView];

			if ((month.month%3)==0)
				pt=NSMakePoint(cadreRect.origin.x+rest.width,pt.y-mvRect.size.height);
			else
				pt.x+=monthSz.width;
		}

		_monthViews=[NSArray arrayWithArray:monthViews];
	}

	for (CalYearMonthView *monthView in _monthViews)
		[monthView setIsSwitchingMode:_isSwitchingMode];

	[self updateVisualInfos];
}

- (BOOL)terminateEdition
{
	if (_myPopover!=nil && _myPopover.isShown==YES)
		return [(CalEventsViewController*)_myPopover.contentViewController terminateEdition:self.window];
	return YES;
}

- (void)willTerminateUI
{
	if (_myPopover!=nil && _myPopover.isShown==YES)
	{
		[_myPopover performClose:nil];
		_myPopover.delegate=nil;
		_myPopover=nil;
	}
}

- (void)setIsSwitchingMode:(BOOL)isSwitchingMode
{
	_isSwitchingMode=isSwitchingMode;
	for (CalYearMonthView *monthView in _monthViews)
		 [monthView setIsSwitchingMode:isSwitchingMode];
}

- (void)calYearDidUpdateEvents:(PCalYear*)sender
{
	if (sender!=_year)
		return;
	for (CalYearMonthView *monthView in _monthViews)
		[monthView setNeedsDisplay:YES];
}

- (void)updateVisualInfos
{
	[PCalUserContext shared].selectedYear=_year.isCurrentYear==YES?0:_year.year;

	[_delegate calYearView:self doAction:@{@"kind":@(6),@"year":_year}];
	[self setNeedsDisplay:YES];
}

- (NSInteger)currentYear {return _year.year; }

- (void)switchToToday:(BOOL)forceReload
{
	[_year switchToToday];
	[_year updateData];
	[_year updateEventsInBackground:YES];
	[self updateVisualInfos];
}

- (void)switchToRelativeYear:(NSInteger)year
{
	[_year switchToRelativeYear:year];
	[_year updateData];
	[_year updateEventsInBackground:YES];
	[self updateVisualInfos];
}

- (void)switchToYear:(NSInteger)year
{
	if (_year.year!=year)
	{
		[_year updateYear:year];
		[_year updateData];
		[_year updateEventsInBackground:YES];
	}
	[self updateVisualInfos];
}

- (void)performUserRequest:(NSString*)request infos:(NSDictionary*)infos
{
	if ([request isEqualToString:@"MODE_MONTH"]==YES)
		[_delegate calYearView:self doAction:@{@"kind":@(3),@"year":_year,@"slow":@([infos[@"slow"] boolValue])}];
	else if ([request isEqualToString:@"PREV_YEAR"]==YES)
		[self switchToRelativeYear:-1];
	else if ([request isEqualToString:@"NEXT_YEAR"]==YES)
		[self switchToRelativeYear:1];
	else if ([request isEqualToString:@"CUR_YEAR_RELOAD"]==YES)
		[self switchToToday:YES];
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//	[[NSColor yellowColor] th_drawInRect:dirtyRect];
//}

#pragma mark -

- (void)monthViewDidUnhighlightMonth:(CalYearMonthView*)sender
{
	for (CalYearMonthView *mv in _monthViews)
		[mv setHeaderPressed:NO];
}

- (void)monthViewDidHighlightMonth:(CalYearMonthView*)sender
{
	for (CalYearMonthView *mv in _monthViews)
		[mv setHeaderPressed:NO];
}

- (void)monthViewDidSelectMonth:(CalYearMonthView*)sender infos:(NSDictionary*)infos
{
	if (_myPopover!=nil && _myPopover.isShown==YES)
	{
		BOOL isOk=[(CalEventsViewController*)_myPopover.contentViewController terminateEdition:self.window];
		[_myPopover performClose:nil];
		if (isOk==NO)
			return;
	}

	PCalMonth *month=sender.month;
	[_delegate calYearView:self doAction:@{@"kind":@(2),@"month":month,@"slow":@([infos[@"slow"] boolValue])}];
}

- (BOOL)monthViewCanPerformAction:(CalYearMonthView*)sender
{
	return YES;
}

- (void)monthView:(CalYearMonthView*)sender performAction:(NSDictionary*)actionInfo
{
	if ([actionInfo[@"kind"] integerValue]==1)
	{
		PCalDate *calDate=actionInfo[@"date"];
		[_delegate calYearView:self doAction:@{@"kind":@(4),@"date":calDate}];
	}
	else if ([actionInfo[@"kind"] integerValue]==2)
	{
		PCalDate *date=actionInfo[@"date"];
		NSRect dateRect=NSRectFromString(actionInfo[@"dateRect"]);

		//NSSize cSize=[(CalEventsViewController*)_myPopover.contentViewController updateForCalDate:date];
		BOOL isSameDate=sender.selectedDate==date?YES:NO;
		
		for (CalYearMonthView *monthView in _monthViews)
			[monthView setSelectDate:(monthView==sender && isSameDate==NO)?date:nil];

		if (date!=nil && isSameDate==NO)
		{
			if (_myPopover==nil)
			{
				CalEventsViewController *calEventsViewController=[[CalEventsViewController alloc] initWithDelegator:self calSource:_calSource];

				_myPopover=[[NSPopover alloc] init];
				_myPopover.contentViewController=calEventsViewController;
				//_myPopover.appearance=NSPopoverAppearanceMinimal;
				_myPopover.animates=NO;
				_myPopover.behavior=NSPopoverBehaviorSemitransient;
				_myPopover.delegate=self;
			}

			NSSize cSize=[(CalEventsViewController*)_myPopover.contentViewController updateForCalDate:date];

//			NSInteger month=sender.month.month;
			NSPoint pPoint=NSZeroPoint;
			NSRectEdge rectEdge=0;

//			if (month==1 || month==4 || month==7 || month==10)
//			{
//				pPoint=NSMakePoint(dateRect.origin.x,dateRect.origin.y+CGFloatFloor(dateRect.size.height/2.0)-CGFloatFloor(cSize.height/2.0));
//				//pPoint.x=-300.0;
//				rectEdge=NSMinXEdge;
//			}
//			else if (month==2 || month==5 || month==8 || month==11)
//			{
//				pPoint=NSMakePoint(dateRect.origin.x+CGFloatFloor(dateRect.size.width/2.0)-CGFloatFloor(cSize.width/2.0),dateRect.origin.y);
//				rectEdge=NSMinYEdge;
//			}
//			else if (month==3 || month==6 || month==9 || month==12)
//			{
//				pPoint=NSMakePoint(dateRect.origin.x,dateRect.origin.y+CGFloatFloor(dateRect.size.height/2.0)-CGFloatFloor(cSize.height/2.0));
//				rectEdge=NSMinXEdge;
//			}

			pPoint=NSMakePoint(dateRect.origin.x,dateRect.origin.y+CGFloatFloor(dateRect.size.height/2.0)-CGFloatFloor(cSize.height/2.0));
			rectEdge=NSMinXEdge;

			NSRect pRect=NSMakeRect(sender.frame.origin.x+pPoint.x,sender.frame.origin.y+pPoint.y,cSize.width,cSize.height);
			_myPopover.contentSize=cSize;
			[_myPopover showRelativeToRect:pRect ofView:self preferredEdge:rectEdge];

			for (CalYearMonthView *monthView in _monthViews)
				[monthView setNeedsDisplay:YES];
		}
		else
		{
			[_myPopover performClose:nil];
		}
	}
	else if ([actionInfo[@"kind"] integerValue]==3)
	{
		PCalEvent *calEvent=actionInfo[@"calEvent"];
		[_delegate calYearView:self doAction:@{@"kind":@(5),@"calEvent":calEvent}];
	}
}

#pragma mark -

- (BOOL)popoverShouldClose:(NSPopover*)popover
{
	if ([(CalEventsViewController*)_myPopover.contentViewController terminateEdition:self.window]==YES)
		return YES;
	return NO;
}

- (void)popoverDidShow:(NSNotification *)notification
{
	for (CalYearMonthView *monthView in _monthViews)
		[monthView setNeedsDisplay:YES];
}

- (void)popoverWillClose:(NSNotification *)notification
{
//	[(CalEventsViewController*)_myPopover.contentViewController terminateByUser];
	for (CalYearMonthView *monthView in _monthViews)
		[monthView setSelectDate:nil];
}

- (void)popoverDidClose:(NSNotification *)notification
{
	_myPopover=nil;
	for (CalYearMonthView *monthView in _monthViews)
		[monthView setNeedsDisplay:YES];
}

#pragma mark -

- (void)calEventsViewController:(CalEventsViewController*)sender didChange:(NSDictionary*)infos
{
	if ([infos[@"kind"] integerValue]==1)
	{
		NSSize size=[infos[@"size"] sizeValue]; 
		_myPopover.contentSize=size;
	}
	else if ([infos[@"kind"] integerValue]==2)
	{
		PCalDate *calDate=infos[@"calDate"];

		[_year updateData];
		[_year updateEventsInBackground:NO];

		for (CalYearMonthView *monthView in _monthViews)
			[monthView setNeedsDisplay:YES];

		PCalDate *nCalDate=[_year calDateWithYear:calDate.year month:calDate.month day:calDate.day];
		THException(nCalDate==nil,@"nCalDate==nil");

		[sender currentCalDateUpdated:nCalDate];
	}
	else if ([infos[@"kind"] integerValue]==3)
	{
		PCalEvent *calEvent=infos[@"calEvent"];
		[_delegate calYearView:self doAction:@{@"kind":@(5),@"calEvent":calEvent}];
	}
}

- (void)keyDown:(NSEvent*)event
{
	THLogDebug(@"keyDown:%@",event);
	if (event.type==NSEventTypeKeyDown)
		[self performUserKeyDown:event.keyCode characters:event.charactersIgnoringModifiers];
}

- (void)performUserKeyDown:(unsigned short)keyCode characters:(NSString*)characters
{
	if (keyCode==kVK_Escape)
	{
		if (_myPopover!=nil && _myPopover.isShown==YES)
			[_myPopover performClose:nil];
		[_delegate calYearView:self doAction:@{@"kind":@(1)}];
	}
}

@end
//---------------------------------------------------------------------------------------------------------------------------------------------
