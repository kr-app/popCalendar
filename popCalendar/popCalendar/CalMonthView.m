// CalMonthView.m

#import "CalMonthView.h"
#import "TH_APP-Swift.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation CalMonthView

#define MarginTop 4.0
#define WeekDayBarHeight 24.0
#define MonthViewHeight 210.0

- (id)initWithFrame:(NSRect)frame delegate:(id)delegate
{
	if (self=[super initWithFrame:frame])
	{
		self.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
		_delegate=delegate;
		_calSource=[PCalSource shared];
	}
	return self;
}

- (BOOL)acceptsFirstResponder { return YES; }

- (BOOL)canBecomeKeyView { return YES; }

//- (void)drawRect:(NSRect)dirtyRect
//{
//	[[NSColor orangeColor] th_drawInRect:self.bounds];
//}

- (NSRect)pageMonthRect
{
	NSSize frameSz=self.frame.size;

	NSRect result=NSMakeRect(	0.0,
													frameSz.height-MonthViewHeight-MarginTop,
													frameSz.width,
													MonthViewHeight-_weekDayView.frame.size.height-MarginTop);

	//result.origin.y+=[self extendedContentSize].height;
	return result;
}

- (NSSize)contentSize
{
	return NSMakeSize(321.0,MarginTop+MonthViewHeight+[self extendedContentSize].height);
}

- (NSSize)extendedContentSize
{
	NSSize result=NSZeroSize;
	NSInteger day=[PCalUserContext shared].selectedDay;
	if (_eventListView!=nil || day>0 || (day==0 && [PCalUserContext shared].doNotSelectToday==NO) || [PCalUserContext shared].firstAutoExpandEventEditor==NO)
	{
		if (_eventEditorViewController==nil)
			_eventEditorViewController=[[EventEditorViewController alloc] initWithDelegator:self];
		result.height+=[CalEventListView frameSizeForEventCount:4].height+_eventEditorViewController.view.frame.size.height;
	}
	return result;
}

- (void)reloadData
{
	NSDate *dateToday=[NSDate date];

	NSInteger year=[PCalUserContext shared].selectedYear;
	NSInteger month=[PCalUserContext shared].selectedMonth;

	if (_pageMonthViews[1]==nil)
	{
		if (year<=0)
			year=[_calSource.calendar components:NSCalendarUnitYear fromDate:dateToday].year;
		if (month<=0)
			month=[_calSource.calendar components:NSCalendarUnitMonth fromDate:dateToday].month;

		PCalMonth *calMonth=[[PCalMonth alloc] initWithSource:_calSource];
		[calMonth setYear:year month:month];
		[calMonth updateWeeksAndMonthEvents];

		NSSize frameSz=self.frame.size;
		_weekDayView=[[PCalWeekDayView alloc] initWithFrame:NSMakeRect(0.0,
																															frameSz.height-WeekDayBarHeight-MarginTop,
																															frameSz.width,
																															WeekDayBarHeight)];
		[self addSubview:_weekDayView];

		_pageMonthViews[1]=[[CalWeekMonthView alloc] initWithFrame:[self pageMonthRect] month:calMonth delegate:self];
		_pageMonthViews[1].autoresizingMask=NSViewWidthSizable|NSViewMinYMargin;
		[self addSubview:_pageMonthViews[1]];
	}
	else
	{
		[_pageMonthViews[1].month updateWeeksAndMonthEvents];
	}

	[_pageMonthViews[1] setIsSwitchingMode:_isSwitchingMode];
	[_pageMonthViews[1] reloadData];

	PCalMonth *calMonth=_pageMonthViews[1].month;

	NSInteger day=[PCalUserContext shared].selectedDay;
	if (day==0 && [PCalUserContext shared].doNotSelectToday==NO)
		day=[_calSource.calendar components:NSCalendarUnitDay fromDate:dateToday].day;

	PCalDate *selectedDate=day>0?[calMonth calDateWithYear:calMonth.year month:calMonth.month day:day]:nil;

	[_pageMonthViews[1] setSelectDate:selectedDate];
	[_weekDayView updateWithDays:_calSource.weekDayLabels displayMode:[PCalUserContext shared].weekDayDisplayMode];

	if (day>0 || [PCalUserContext shared].firstAutoExpandEventEditor==NO)
	{
		[PCalUserContext shared].firstAutoExpandEventEditor=YES;

		NSString *selectedEvent=[[PCalUserContext shared] selectedEventForDate:selectedDate];
		PCalEvent *event=[selectedDate eventWithIdentifier:selectedEvent];
		[self displayEvents:YES winOffset:NULL forDate:selectedDate selectedEvent:event animated:NO];
	}

	[self informMonthDidChange];
}

- (BOOL)terminateEdition
{
	return [self userWantTerminateCurrentEventEdition];
}

- (void)willTerminateUI
{
	[self userWantTerminateCurrentEventEdition];
}

- (BOOL)userWantTerminateCurrentEventEdition
{
	if (_eventEditorViewController!=nil && [_eventEditorViewController terminateEdition:self.window completion:NULL]==NO)
		return NO;
	return YES;
}

- (void)setIsSwitchingMode:(BOOL)isSwitchingMode
{
	_isSwitchingMode=isSwitchingMode;
	[_pageMonthViews[1] setIsSwitchingMode:isSwitchingMode];

//	if (_eventListView!=nil)
//		_eventListView.autoresizingMask=NSViewWidthSizable|(isSwitchingMode==YES?NSViewMaxYMargin:NSViewMinYMargin);
}

- (void)informMonthDidChange
{
	CalWeekMonthView *monthView=_pageMonthViews[1];
	PCalMonth *month=monthView.month;

	[self selectedDateDidChange];

	[_delegate calMonthView:self doAction:@{@"kind":@(6),@"month":month}];
	[self setNeedsDisplay:YES];
}

- (void)selectedDateDidChange
{
	CalWeekMonthView *monthView=_pageMonthViews[1];
	PCalDate *selectedDate=monthView.selectedDate;

	[PCalUserContext shared].selectedYear=monthView.month.isCurrentMonth==YES?0:selectedDate.year;
	[PCalUserContext shared].selectedMonth=monthView.month.isCurrentMonth==YES?0:selectedDate.month;
	[PCalUserContext shared].selectedDay=selectedDate.isToday==YES?0:selectedDate.day;
}

- (void)updateSelectedDateOfMonthView:(CalWeekMonthView*)monthView
{
	PCalDate *date=monthView.selectedDate;
	PCalEvent *selectedEvent=[date eventWithIdentifier:[[PCalUserContext shared] selectedEventForDate:date]];

	[_eventListView updateWithCalDate:monthView.selectedDate events:monthView.selectedDate.events selectedEvent:selectedEvent.eventIdentifier];
	[_eventEditorViewController updateUIWithCalDate:monthView.selectedDate calEvent:selectedEvent calSource:_calSource];
}

- (void)switchToToday:(BOOL)forceReload
{
	[self userWantTerminateCurrentEventEdition];
	CalWeekMonthView *monthView=_pageMonthViews[1];

 	if (monthView.month.isCurrentMonth==NO || forceReload==YES)
	{
		[monthView.month switchToToday];
		[monthView.month updateWeeksAndMonthEvents];

		[monthView reloadData];
		[monthView setSelectDate:[monthView.month todayCalDate]];
	}
	else
		[monthView setSelectDate:[monthView.month todayCalDate]];

	[self updateSelectedDateOfMonthView:monthView];
	[self informMonthDidChange];
}

- (void)switchToRelativeMonth:(NSInteger)month dateToSelect:(NSDateComponents*)dateToSelect
{
	[self userWantTerminateCurrentEventEdition];
	CalWeekMonthView *monthView=_pageMonthViews[1];

	[monthView.month switchToRelativeMonth:month];
	[monthView.month updateWeeksAndMonthEvents];

	[monthView reloadData];
	[monthView setSelectDate:[monthView.month calDateWithDateComponents:dateToSelect]];

	[self updateSelectedDateOfMonthView:monthView];
	[self informMonthDidChange];
}

- (void)switchToYear:(NSInteger)year month:(NSInteger)month
{
	[self userWantTerminateCurrentEventEdition];
	CalWeekMonthView *monthView=_pageMonthViews[1];

	if (monthView.month.year!=year || monthView.month.month!=month)
	{
		[monthView.month setYear:year month:month];
		[monthView.month updateWeeksAndMonthEvents];
	}

	[monthView reloadData];
	[monthView setSelectDate:nil/*[monthView.month calDateWithDateComponents:_dateComponentsToHighlight]*/];

	[self updateSelectedDateOfMonthView:monthView];
	[self informMonthDidChange];
}

#pragma mark -

- (BOOL)monthViewCanPerformAction:(CalWeekMonthView*)sender
{
	return (_isDragging==YES || _isAnimating==YES)?NO:YES;
}

- (void)monthView:(CalWeekMonthView*)sender performAction:(NSDictionary*)actionInfo
{
	if ([actionInfo[@"kind"] integerValue]==1) // Show Date in Calendar App
		[_delegate calMonthView:self doAction:@{@"kind":@(4),@"date":actionInfo[@"date"]}];
	else if ([actionInfo[@"kind"] integerValue]==2) // Selected Date Change
	{
		if (_isAnimating==YES)
			return;

		if ([self userWantTerminateCurrentEventEdition]==NO)
			return;

		PCalDate *date=actionInfo[@"date"];
		BOOL slow=([actionInfo[@"event"] modifierFlags]&NSEventModifierFlagShift)!=0?YES:NO;
		BOOL isSameDate=sender.selectedDate==date?YES:NO;

		[PCalUserContext shared].doNotSelectToday=(isSameDate&& date.isToday)?YES:NO;

		[sender setSelectDate:isSameDate==YES?nil:date];

		PCalEvent *selectedEvent=[date eventWithIdentifier:[[PCalUserContext shared] selectedEventForDate:date]];

		if (date==nil)
			;
		else if (isSameDate==YES)
			[self windowExpandedForEvents:NO date:nil selectedEvent:selectedEvent animDuration:slow==YES?1.0:0.15];
		else if (_eventListView==nil)
			[self windowExpandedForEvents:YES date:date selectedEvent:selectedEvent animDuration:slow==YES?1.0:0.15];
		else
			[self displayEvents:YES winOffset:NULL forDate:date selectedEvent:selectedEvent animated:NO];

		[self selectedDateDidChange];
	}
	else if ([actionInfo[@"kind"] integerValue]==3) //New Event
	{
		PCalEvent *calEvent=actionInfo[@"calEvent"];
		[_delegate calMonthView:self doAction:@{@"kind":@(5),@"calEvent":calEvent}];
	}
}

#pragma mark -

- (void)displayEvents:(BOOL)displayEvents winOffset:(NSSize*)pWinOffset forDate:(PCalDate*)date selectedEvent:(PCalEvent*)selectedEvent animated:(BOOL)animated
{
	if (displayEvents==YES)
	{
		if (_eventListView==nil)
		{
			//NSUInteger eventsCount=date.events.count;
			NSSize evlSize=[CalEventListView frameSizeForEventCount:4/*eventsCount<4?4:eventsCount>10?10:eventsCount*/];

			_eventListView=[[CalEventListView alloc] initWithFrame:NSMakeRect(0.0,_pageMonthViews[1].frame.origin.y-evlSize.height,self.frame.size.width,evlSize.height)];
			_eventListView.autoresizingMask=NSViewWidthSizable|NSViewMinYMargin;
			_eventListView.alphaValue=animated==YES?0.0:1.0;
			_eventListView.delegator=self;
			_eventListView.drawTopLine=YES;
			[self addSubview:_eventListView];

			if (_eventEditorViewController==nil) // pour le content size
				_eventEditorViewController=[[EventEditorViewController alloc] initWithDelegator:self];
			_eventEditorViewController.view.autoresizingMask=NSViewWidthSizable|NSViewMinYMargin;
			_eventEditorViewController.view.alphaValue=animated==YES?0.0:1.0;
			[_eventEditorViewController setDrawTopLine:YES];

			NSSize evSize=_eventEditorViewController.view.frame.size;
			_eventEditorViewController.view.frame=NSMakeRect(0.0,_eventListView.frame.origin.y-evSize.height,self.frame.size.width,evSize.height);
			[self addSubview:_eventEditorViewController.view];

			if (pWinOffset!=NULL)
				*pWinOffset=NSMakeSize(0.0,evlSize.height+evSize.height);
		}

		[_eventListView updateWithCalDate:date events:date.events selectedEvent:selectedEvent.eventIdentifier];

		[_eventEditorViewController updateUIWithCalDate:date calEvent:selectedEvent calSource:_calSource];

		if (animated==YES)
		{
			[_eventListView setAlphaValue:1.0 withAnimator:YES];
			[_eventEditorViewController.view setAlphaValue:1.0 withAnimator:YES];
		}
	}
	else
	{
		if (_eventListView!=nil)
		{
			if (pWinOffset!=NULL)
				*pWinOffset=NSMakeSize(0.0,_eventListView.frame.size.height+_eventEditorViewController.view.frame.size.height);

			if (animated==YES)
			{
				[_eventListView setAlphaValue:0.0 withAnimator:YES];
				[_eventEditorViewController.view setAlphaValue:0.0 withAnimator:YES];
			}
			else
			{
				[_eventListView removeFromSuperview];
				_eventListView=nil;
				[_eventEditorViewController.view removeFromSuperview];
				_eventEditorViewController=nil;
			}
		}
	}
}

- (void)windowExpandedForEvents:(BOOL)isExpanded date:(PCalDate*)date selectedEvent:(PCalEvent*)selectedEvent animDuration:(CGFloat)animDuration
{
	if (isExpanded==YES)
	{
		if (_eventListView==nil)
		{
			if (animDuration>0.0)
			{
				//_pageMonthViews[1].autoresizingMask=NSViewWidthSizable|NSViewMinYMargin;

				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
				{
					_isAnimating=YES;
					context.duration=animDuration;

					NSSize offset=NSZeroSize;
					[self displayEvents:YES winOffset:&offset forDate:date selectedEvent:selectedEvent animated:YES];
					[(PCalWindow*)self.window setNewSize:NSMakeSize(self.window.frame.size.width,self.window.frame.size.height+offset.height) withAnimator:YES];
				}
				completionHandler:^
				{
					_isAnimating=NO;
					//_pageMonthViews[1].autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
				}];
			}
			else
			{
				NSSize offset=NSZeroSize;
				[self displayEvents:YES winOffset:&offset forDate:date selectedEvent:selectedEvent animated:NO];
				[(PCalWindow*)self.window resize_withNewSize:NSMakeSize(self.window.frame.size.width,self.window.frame.size.height-offset.height) display:NO];
			}
		}
	}
	else
	{
		if (_eventListView!=nil)
		{
			if (animDuration>0.0)
			{
				//_pageMonthViews[1].autoresizingMask=NSViewWidthSizable|NSViewMinYMargin;

				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
				{
					_isAnimating=YES;
					context.duration=animDuration;

					NSSize offset=NSZeroSize;
					[self displayEvents:NO winOffset:&offset forDate:date selectedEvent:selectedEvent animated:YES];
					[(PCalWindow*)self.window setNewSize:NSMakeSize(self.window.frame.size.width,self.window.frame.size.height-offset.height) withAnimator:YES];
				}
				completionHandler:^
				{
					_isAnimating=NO;
					[self displayEvents:NO winOffset:NULL forDate:date selectedEvent:selectedEvent animated:NO];
					//_pageMonthViews[1].autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
				 }];
			}
			else
			{
				NSSize offset=NSZeroSize;
				[self displayEvents:NO winOffset:&offset forDate:date selectedEvent:selectedEvent animated:NO];
				[(PCalWindow*)self.window resize_withNewSize:NSMakeSize(self.window.frame.size.width,self.window.frame.size.height-offset.height) display:NO];
			}
		}
	}
}

#pragma mark -

- (void)beginDraggedPageView
{
	[self userWantTerminateCurrentEventEdition];

	_pageMonthViews[0].needRecalculateFramePosition=YES;
	[_pageMonthViews[1] setSelectDate:nil];
	_pageMonthViews[2].needRecalculateFramePosition=YES;

	[_eventListView updateWithCalDate:nil events:nil selectedEvent:nil];
	[_eventEditorViewController updateUIWithCalDate:nil calEvent:nil calSource:_calSource];
}

- (void)updateDraggedPageViewWithDelta:(CGFloat)delta
{
	NSSize frameSz=self.frame.size;
	CalWeekMonthView *pageView=_pageMonthViews[1];

	NSInteger pIndex=delta>0.0?0:2;
	NSInteger monthOffSet=delta>0.0?-1:1;

	if (_pageMonthViews[pIndex]==nil || _pageMonthViews[pIndex].superview!=self)
	{
		PCalMonthRelative *relativeMonth=[pageView.month yearAndMonthFromRelativeMonth:monthOffSet];
		if (relativeMonth.year==0 && relativeMonth.month==0)
		{
			THLogError(@"getYear:month:fromRelativeMonth:");
			return;
		}

		if (_pageMonthViews[pIndex]==nil)
		{
			PCalMonth *calMonth=[[PCalMonth alloc] initWithSource:_calSource];
			[calMonth setYear:relativeMonth.year month:relativeMonth.month];
			[calMonth updateWeeksAndMonthEvents];

			NSRect pmRect=NSMakeRect(0.0,pageView.frame.origin.y,pageView.frame.size.width,pageView.frame.size.height);
			_pageMonthViews[pIndex]=[[CalWeekMonthView alloc] initWithFrame:pmRect month:calMonth delegate:self];
			_pageMonthViews[pIndex].autoresizingMask=NSViewWidthSizable|NSViewMinYMargin;
		}
		else if (_pageMonthViews[pIndex].needRecalculateFramePosition==YES)
		{
			_pageMonthViews[pIndex].needRecalculateFramePosition=NO;
			_pageMonthViews[pIndex].frame=NSMakeRect(0.0,pageView.frame.origin.y,pageView.frame.size.width,pageView.frame.size.height);
		}

		if (_pageMonthViews[pIndex].month.year!=relativeMonth.year || _pageMonthViews[pIndex].month.month!=relativeMonth.month)
		{
			[_pageMonthViews[pIndex].month setYear:relativeMonth.year month:relativeMonth.month];
			[_pageMonthViews[pIndex].month updateWeeksAndMonthEvents];
		}

		[_pageMonthViews[pIndex] reloadData];
	}

	NSPoint nPoint=NSMakePoint(pageView.frame.origin.x+delta,pageView.frame.origin.y);

	if (pIndex==0 && (nPoint.x>frameSz.width))
		nPoint.x=frameSz.width;
	else if (pIndex==2 && (nPoint.x<(0.0-frameSz.width)))
		nPoint.x=0.0-frameSz.width;

	[pageView setFrameOrigin:nPoint];

	NSRect pvRect=pageView.frame;
	[_pageMonthViews[0] setFrameOrigin:NSMakePoint(pvRect.origin.x-pvRect.size.width,pvRect.origin.y)];
	[_pageMonthViews[2] setFrameOrigin:NSMakePoint(pvRect.origin.x+pvRect.size.width,pvRect.origin.y)];

	_pageMonthViews[0].alphaValue=frameSz.width/(frameSz.width-_pageMonthViews[0].frame.origin.x);
	_pageMonthViews[2].alphaValue=1.0-(_pageMonthViews[2].frame.origin.x/frameSz.width);

	if (_pageMonthViews[pIndex].superview!=self)
		[self addSubview:_pageMonthViews[pIndex]];

	if (pageView.frame.origin.x>0.0)
		pageView.alphaValue=1.0-(pvRect.origin.x/frameSz.width);
	else
		pageView.alphaValue=(pvRect.size.width-pvRect.origin.x*-1.0)/frameSz.width;
}

- (void)endDraggedPageViewWithDelta:(CGFloat)delta
{
	NSSize frameSz=self.frame.size;
	NSInteger direction=delta<=-60.0?-1:delta>=60.0?1:0;

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
	{
		_isAnimating=YES;
		context.duration=1.0;
		NSRect pvRect1=_pageMonthViews[1].frame;

		if (direction==-1)
		{
			[_pageMonthViews[1] setFrame:NSMakeRect(0.0-pvRect1.size.width,_pageMonthViews[1].frame.origin.y,pvRect1.size.width,pvRect1.size.height) withAnimator:YES];
			[_pageMonthViews[1] setAlphaValue:0.0 withAnimator:YES];

			[_pageMonthViews[2] setFrame:NSMakeRect(0.0,_pageMonthViews[2].frame.origin.y,_pageMonthViews[2].frame.size.width,_pageMonthViews[2].frame.size.height) withAnimator:YES];
			[_pageMonthViews[2] setAlphaValue:1.0 withAnimator:YES];
		}
		else if (direction==1)
		{
			[_pageMonthViews[1] setFrame:NSMakeRect(frameSz.width,pvRect1.origin.y,_pageMonthViews[1].frame.size.width,pvRect1.size.height) withAnimator:YES];
			[_pageMonthViews[1] setAlphaValue:0.0 withAnimator:YES];

			[_pageMonthViews[0] setFrame:NSMakeRect(0.0,_pageMonthViews[0].frame.origin.y,_pageMonthViews[0].frame.size.width,_pageMonthViews[0].frame.size.height) withAnimator:YES];
			[_pageMonthViews[0] setAlphaValue:1.0 withAnimator:YES];
		}
		else
		{
			[_pageMonthViews[1] setFrame:NSMakeRect(0.0,pvRect1.origin.y,pvRect1.size.width,pvRect1.size.height) withAnimator:YES];
			[_pageMonthViews[1] setAlphaValue:1.0 withAnimator:YES];

			if (delta>0.0)
			{
				[_pageMonthViews[0] setFrame:NSMakeRect(0.0-_pageMonthViews[0].frame.size.width,0.0,_pageMonthViews[0].frame.size.width,_pageMonthViews[0].frame.size.height) withAnimator:YES];
				[_pageMonthViews[0] setAlphaValue:0.0 withAnimator:YES];
			}
			else if (delta<0.0)
			{
				[_pageMonthViews[2] setFrame:NSMakeRect(frameSz.width,_pageMonthViews[2].frame.origin.y,_pageMonthViews[2].frame.size.width,_pageMonthViews[2].frame.size.height) withAnimator:YES];
				[_pageMonthViews[2] setAlphaValue:0.0 withAnimator:YES];
			}
		}
	}
	completionHandler:^
	{
		_isAnimating=NO;

		CalWeekMonthView *pageView=_pageMonthViews[1];

		if (direction==-1)
		{
			_pageMonthViews[1]=_pageMonthViews[2];
			_pageMonthViews[2]=pageView;
		}
		else if (direction==1)
		{
			_pageMonthViews[1]=_pageMonthViews[0];
			_pageMonthViews[0]=pageView;
		}

		[_pageMonthViews[0] removeFromSuperview];
		[_pageMonthViews[2] removeFromSuperview];

		_pageMonthViews[0]=nil;
		_pageMonthViews[2]=nil;

		[self informMonthDidChange];
	}];
}

#pragma mark -

- (void)mouseDown:(NSEvent*)event
{
	_isDragging=NO;
	_downPoint=[self convertPoint:event.locationInWindow fromView:nil];
	[super mouseDown:event];
}

- (void)mouseUp:(NSEvent*)event
{
	if (_isDragging==YES)
	{
		CGFloat delta=CGFloatFloor(_pageMonthViews[1].frame.origin.x);
		[self endDraggedPageViewWithDelta:delta];
		_isDragging=NO;
		_downPoint=NSZeroPoint;
		return;
	}

	[super mouseDown:event];
}

- (void)mouseDragged:(NSEvent*)event
{
	if (_isDragging==NO)
	{
		if (_isAnimating==YES)
			return;

		NSPoint point=[self convertPoint:event.locationInWindow fromView:nil];
		if (NSMouseInRect(point,[self pageMonthRect],NO)==NO)
			return;
		if (TH_IsEqualNSPoint(point,_downPoint,5.0)==YES)
			return;

		_isDragging=YES;
		_isAnimating=YES;
		[self beginDraggedPageView];
	}

	CGFloat delta=CGFloatFloor(event.deltaX);
	[self updateDraggedPageViewWithDelta:delta];
}

//- (void)scrollWheel:(NSEvent*)event
//{
//	if (_isDragging==YES || _isAnimating==YES)
//		return;
//
//	NSEventPhase phase=theEvent.momentumPhase;
//
//	CGFloat delta=theEvent.scrollingDeltaX;
//	THLogDebug(@"phase:%ld delta:%f",phase,delta);
//
////	if (_scrollWheelStatus==-1 && (delta!=0 && phase!=NSEventPhaseBegan))
////		return;
//
//	if (phase==NSEventPhaseBegan/* || _scrollWheelStatus==0 || _scrollWheelStatus==-1*/)
//	{
//		THLogDebug(@"1");
//
//		NSPoint point=[self convertPoint:event.locationInWindow fromView:nil];
//		if (NSMouseInRect(point,_pageMonthViews[1].frame,NO)==NO)
//			return;
//
////		_scrollWheelStatus=1;
//		_scrollDelta=0.0;
//
//		_scrollDelta-=delta;
//		[self updateDraggedPageViewWithDelta:delta];
//	}
//	else if (phase==NSEventPhaseChanged/* || (_scrollWheelStatus==1 && delta!=0.0)*/)
//	{
//		THLogDebug(@"2");
//		_scrollDelta-=delta;
//		[self updateDraggedPageViewWithDelta:delta];
//
//		if (_scrollDelta>=100.0)
//		{
////			_scrollWheelStatus=-1;
//			[self endDraggedPageViewWithDelta:-60.0];
//		}
//		else if (_scrollDelta<=-100.0)
//		{
////			_scrollWheelStatus=-1;
//			[self endDraggedPageViewWithDelta:60.0];
//		}
//	}
//	else if (phase==NSEventPhaseEnded || phase==NSEventPhaseCancelled/* || (_scrollWheelStatus==1 && delta==0)*/)
//	{
//		THLogDebug(@"3");
////		_scrollWheelStatus=-1;
//		[self endDraggedPageViewWithDelta:_scrollDelta];
//	}
//	else
//	{
//		THLogDebug(@"4");
//	}
//}

#pragma mark -

- (void)performUserRequest:(NSString*)request infos:(NSDictionary*)infos
{
	if ([request isEqualToString:@"MODE_YEAR"]==YES)
	{
		CalWeekMonthView *monthView=_pageMonthViews[1];
		[_delegate calMonthView:self doAction:@{@"kind":@(2),@"month":monthView.month,@"slow":@([infos[@"slow"] boolValue])}];
	}
	else if ([request isEqualToString:@"PREV_MONTH"]==YES)
		[self switchToRelativeMonth:-1 dateToSelect:nil];
	else if ([request isEqualToString:@"NEXT_MONTH"]==YES)
		[self switchToRelativeMonth:1 dateToSelect:nil];
	else if ([request isEqualToString:@"CUR_MONTH_RELOAD"]==YES)
		[self switchToToday:YES];
}

- (void)keyDown:(NSEvent*)event
{
	THLogDebug(@"keyDown:%@",event);
	if (event.type==NSEventTypeKeyDown)
		[self performUserKeyDown:event.keyCode characters:event.charactersIgnoringModifiers];
}

- (void)performUserKeyDown:(unsigned short)keyCode characters:(NSString*)characters
{
	if (_isDragging==YES || _isAnimating==YES)
		return;

//	if (_eventEditorViewController!=nil && _eventEditorViewController.calEvent!=nil)
//	{
//		[_calSource cancelChangesOfCalEvent:_eventEditorViewController.calEvent];
//		[_eventEditorViewController updateUI];
//	}

	if (keyCode==kVK_Escape)
	{
		[_delegate calMonthView:self doAction:@{@"kind":@(1)}];
	}
	else if (keyCode==kVK_LeftArrow || keyCode==kVK_RightArrow || keyCode==kVK_UpArrow || keyCode==kVK_DownArrow)
	{
		CalWeekMonthView *monthView=_pageMonthViews[1];
		char direction=keyCode==kVK_LeftArrow?'l':keyCode==kVK_RightArrow?'r':keyCode==kVK_UpArrow?'t':keyCode==kVK_DownArrow?'b':0;

		PCalDate *highlightedDate=monthView.selectedDate;
		if (highlightedDate!=nil)
			highlightedDate=[monthView.month calDateWithYear:highlightedDate.year month:highlightedDate.month day:highlightedDate.day];

		if (highlightedDate==nil)
		{
			NSDateComponents *comps=[_calSource.calendar components:NSCalendarUnitDay fromDate:[NSDate date]];
			[monthView setSelectDate:[monthView.month calDateWithYear:monthView.month.year month:monthView.month.month day:comps!=nil?comps.day:1]];
			return;
		}
		else
		{
			NSDateComponents *comps=[_calSource dateComponentsByChangingKeyboardDirection:[NSString stringWithFormat:@"%c",direction] fromCalDate:highlightedDate];
			PCalDate *calDate=[monthView.month calDateWithDateComponents:comps];
			if (calDate!=nil)
			{
				[monthView setSelectDate:calDate];
				[self updateSelectedDateOfMonthView:monthView];
			}
			else
				[self switchToRelativeMonth:(direction=='l' || direction=='t')?-1:(direction=='r' || direction=='b')?1:0 dateToSelect:comps];
		}
	}
//	else if (keyCode==36) // Enter
//	{
//		CalWeekMonthView *pageView=_pageMonthViews[1];
//		[pageView performHighlightCalDate:pageView.highlightedDate];
//	}
	else if ([characters isEqualToString:@"t"]==YES) // touche "t'
		[self switchToToday:NO];
}

#pragma mark -

- (BOOL)calEventListViewShouldChangeSelection:(CalEventListView*)sender
{
	if (_isAnimating==YES)
		return NO;
	return [self userWantTerminateCurrentEventEdition];
}

- (void)calEventListView:(CalEventListView*)sender didSelectCalEvent:(PCalEvent*)calEvent
{
	if (_isAnimating==YES)
		return;

	if ([self userWantTerminateCurrentEventEdition]==NO)
		return;

	[[PCalUserContext shared] setSelectedEvent:calEvent.eventIdentifier forDate:sender.calDate];
	[_eventEditorViewController updateUIWithCalDate:sender.calDate calEvent:calEvent calSource:_calSource];
}

- (void)calEventListView:(CalEventListView*)sender wantsNewCalEvent:(NSDictionary*)infos
{
	if (_isAnimating==YES)
		return;

	PCalEvent *calEvent=[PCalUserInterration performCreateEventForDate:sender.calDate calSource:_calSource window:self.window];
	if (calEvent==nil)
		return;

	[self calEventListView:sender didSelectCalEvent:calEvent];
}

- (void)calEventListView:(CalEventListView*)sender revealCalEventInCalApp:(PCalEvent*)calEvent
{
	if (_isAnimating==YES || calEvent==nil)
		return;
	[_delegate calMonthView:self doAction:@{@"kind":@(5),@"calEvent":calEvent}];
}

- (void)calEventListView:(CalEventListView*)sender deleteCalEvent:(PCalEvent*)calEvent
{
	if (_isAnimating==YES)
		return;

	NSString *error=[_calSource removeCalEvent:calEvent];
	if (error!=nil)
	{
		THLogError(@"removeCalEvent==NO error:%@",error);
		return;
	}

	[_pageMonthViews[1].month updateWeeksAndMonthEvents];
	[_pageMonthViews[1] reloadData];

	PCalDate *date=sender.calDate;
	PCalDate *nCalDate=[_pageMonthViews[1].month calDateWithYear:date.year month:date.month day:date.day];
	[_pageMonthViews[1] setSelectDate:nCalDate];

	[[PCalUserContext shared] setSelectedEvent:nil forDate:date];

	[_eventListView updateWithCalDate:nCalDate events:nCalDate.events selectedEvent:nil];
	if (_eventEditorViewController!=nil)
	{
		//NSArray *sourcesCalendars=[_calSource sourcesCalendarsWithOptions:PCalSourceCalendarListOptionNoExcluded];
		[_eventEditorViewController updateUIWithCalDate:nCalDate calEvent:nil calSource:_calSource];
	}
}

#pragma mark -

- (BOOL)eventEditorViewController:(EventEditorViewController*)sender terminateEdition:(NSString*)action errorInfo:(NSDictionary**)pErrorInfo
{
	if (_isAnimating==YES)
		return NO;

	PCalEvent *calEvent=sender.calEvent;

	if ([action isEqualToString:@"delete"]==YES || [action isEqualToString:@"save"]==YES)
	{
		//[sender.loadingIndicator startAnimation:nil];

		NSString *error=nil;

		if ([action isEqualToString:@"delete"]==YES)
			error=[_calSource removeCalEvent:calEvent];
		else if ([action isEqualToString:@"save"]==YES)
			error=[_calSource saveChangesOfCalEvent:calEvent];

		[_pageMonthViews[1].month updateWeeksAndMonthEvents];
		[_pageMonthViews[1] reloadData];

		PCalDate *nCalDate=[_pageMonthViews[1].month calDateWithYear:sender.calDate.year month:sender.calDate.month day:sender.calDate.day];
		[_pageMonthViews[1] setSelectDate:nCalDate];

		[_eventListView updateWithCalDate:nCalDate events:nCalDate.events selectedEvent:[action isEqualToString:@"save"]==YES?calEvent.eventIdentifier:nil];

		//[sender.loadingIndicator stopAnimation:nil];

		if (error!=nil)
		{
			THLogError(@"isOk==NO error:%@",error);

			if ([action isEqualToString:@"delete"]==YES)
				(*pErrorInfo)=[NSDictionary dictionaryWithObjectsAndKeys:THLocalizedString(@"Can not delete event."),@"title",error,@"error",nil];
			else if ([action isEqualToString:@"save"]==YES)
				(*pErrorInfo)=[NSDictionary dictionaryWithObjectsAndKeys:THLocalizedString(@"Can not save event."),@"title",error,@"error",nil];
		}

//		if (isOk==YES && [action isEqualToString:@"delete"]==YES)
//			[self displayEvents:YES winOffset:NULL forDate:sender.calDate selectedEvent:nil animated:NO];

		return error==nil?YES:NO;
	}

	[calEvent cancelChanges];

	[_eventListView selectEvent:nil];
	[self displayEvents:YES winOffset:NULL forDate:sender.calDate selectedEvent:nil animated:NO];

	return YES;
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
