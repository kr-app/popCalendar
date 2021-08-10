// PaneViewController.m

#import "PaneViewController.h"
#import "TH_APP-Swift.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation PaneViewController

#define WinRightMargin 20.0
#define CalContentViewBorder 4.0

- (id)initWithDelegator:(id)delegator
{
	if (self=[super initWithNibName:[self className] bundle:nil])
	{
		_delegator=delegator;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(n_calSourceDidChange:) name:PCalSource.didChangeNotification object:nil];
	}
	return self;
}

- (void)loadView
{
	[super loadView];

	_topYearView=[[PaneTopYearView alloc] initWithFrame:self.headerView.bounds mode:@"y" delegator:self];
	_topMonthView=[[PaneTopYearView alloc] initWithFrame:self.headerView.bounds mode:@"m" delegator:self];
	
	self.headerView.menu=[MoreMenu shared].menu;

//	[(THBgColorView*)self.calContentView setBgColor:[NSColor greenColor]];
}

#pragma mark -

- (void)n_calSourceDidChange:(NSNotification*)notification
{
	THLogDebug(@"notification:%@",notification);

	if ([[NSApplication sharedApplication] isActive]==YES)
		return;

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshData) object:nil];
	[self performSelector:@selector(refreshData) withObject:nil afterDelay:1.0];
}

- (void)windowDidResignKey:(NSNotification*)notification
{
	if (_myWindow!=notification.object || [self canHidePanelWindow]==NO || _isHidding==YES)
		return;
	[_delegator paneViewControllerWantsHide:self];
}

#pragma mark -

- (void)refreshData
{
	if ([self isVisiblePanel]==NO || _isShowing==YES || _isHidding==YES || _isSwitching==YES)
		return;

	if ([PCalUserContext shared].viewMode==PCalViewModeByYear)
		[_calYearView reloadData];
	else if ([PCalUserContext shared].viewMode==PCalViewModeByMonth)
		[_calMonthView reloadData];
}

- (void)prepareContentViewForMode:(NSInteger)displayMode
{
	if (displayMode==PCalViewModeByYear)
	{
		NSRect vRect=NSMakeRect(CalContentViewBorder,0.0,[CalYearView contentSize].width,[CalYearView contentSize].height);
		vRect.origin.y=self.calContentView.frame.size.height-vRect.size.height;
		if (_calYearView==nil)
			_calYearView=[[CalYearView alloc] initWithFrame:vRect delegate:self];
		else if (NSEqualRects(_calYearView.frame,vRect)==NO)
			_calYearView.frame=vRect;
	}
	else
	{
		NSRect vRect=NSMakeRect(0.0,0.0,self.calContentView.frame.size.width,self.calContentView.frame.size.height);
		if (_calMonthView==nil)
			_calMonthView=[[CalMonthView alloc] initWithFrame:vRect delegate:self];
		else if (NSEqualRects(_calMonthView.frame,vRect)==NO)
			_calMonthView.frame=vRect;
	}
}

- (void)switchViewToDisplayMode:(NSInteger)displayMode animated:(BOOL)animated infos:(NSDictionary*)infos
{
	THLogDebug(@"displayMode:%ld",displayMode);

	if (_isSwitching==YES)
		return;

	NSInteger fromMode=[PCalUserContext shared].viewMode;

	if (fromMode==PCalViewModeByYear && displayMode==PCalViewModeByMonth)
		[_calYearView willTerminateUI];	
	else if (fromMode==PCalViewModeByMonth && displayMode==PCalViewModeByYear)
		[_calMonthView willTerminateUI];	

	[PCalUserContext shared].viewMode=displayMode;

	[_calYearView setIsSwitchingMode:animated];
	[_calMonthView setIsSwitchingMode:animated];

	[self prepareContentViewForMode:displayMode];

	if (displayMode==PCalViewModeByMonth)
	{
		[_calMonthView setIsSwitchingMode:animated];
		[_calMonthView reloadData];

		if (infos!=nil && [infos[@"action"] integerValue]==1)
			[_calMonthView switchToYear:[infos[@"year"] integerValue] month:[infos[@"month"] integerValue]];

		_calMonthView.alphaValue=animated==YES?0.0:1.0;
		if (_calMonthView.superview!=self.calContentView)
			[self.calContentView addSubview:_calMonthView];
	}
	else
	{
		[_calYearView setIsSwitchingMode:animated];
		[_calYearView reloadData];

		if (infos!=nil && [infos[@"action"] integerValue]==2)
			[_calYearView switchToYear:[infos[@"year"] integerValue]];

		_calYearView.alphaValue=animated==YES?0.0:1.0;
		if (_calYearView.superview!=self.calContentView)
			[self.calContentView addSubview:_calYearView];
	}

	PaneTopYearView *topYearViewTo=displayMode==PCalViewModeByYear?_topYearView:_topMonthView;
	PaneTopYearView *topYearViewFrom=displayMode==PCalViewModeByYear?_topMonthView:_topYearView;
	topYearViewTo.frame=self.headerView.bounds;

	topYearViewTo.hidden=NO;
	topYearViewFrom.hidden=YES;

	if (animated==YES)
	{
		_isSwitching=YES;

		NSSize vSize=[self windowSizeForDisplayMode:displayMode];
		NSRect wFrame=_myWindow.frame;
//		NSRect visibleRect=_myWindow.screen.visibleFrame;

		NSRect nwFrame=wFrame;
		nwFrame.size=vSize;
		nwFrame.origin.y-=vSize.height-wFrame.size.height;
		nwFrame.origin.x-=(_showedSens=='<')?(vSize.width-wFrame.size.width):0.0;

//		if ((nwFrame.origin.x+nwFrame.size.width+WinRightMargin)>visibleRect.size.width)
//			nwFrame.origin.x=visibleRect.size.width-nwFrame.size.width-WinRightMargin;

//		topYearViewTo.alphaValue=0.0;
//		topYearViewFrom.alphaValue=1.0;

		if (topYearViewTo.superview!=self.headerView)
			[self.headerView addSubview:topYearViewTo];
		if (topYearViewFrom.superview!=self.headerView)
			[self.headerView addSubview:topYearViewFrom];

		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
		{
			context.duration=[infos[@"slow"] boolValue]==YES?1.0:0.15;
			[(NSWindow*)_myWindow.animator setFrame:nwFrame display:YES];

//			[(NSView*)topYearViewTo.animator setAlphaValue:1.0];
//			[(NSView*)topYearViewFrom.animator setAlphaValue:0.0];

			[displayMode==PCalViewModeByMonth?_calYearView:_calMonthView setAlphaValue:0.0 withAnimator:YES];
			[displayMode==PCalViewModeByMonth?_calMonthView:_calYearView setAlphaValue:1.0 withAnimator:YES];
		}
		completionHandler:^
		{
			_isSwitching=NO;

			[_myWindow makeFirstResponder:displayMode==PCalViewModeByMonth?_calMonthView:_calYearView];

			[_calYearView setIsSwitchingMode:NO];
			[_calMonthView setIsSwitchingMode:NO];

//			[topYearViewFrom performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1];
			[displayMode==PCalViewModeByMonth?_calYearView:_calMonthView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1];
		}];
	}
	else
	{
		topYearViewTo.alphaValue=1.0;
		if (topYearViewTo.superview!=self.headerView)
			[self.headerView addSubview:topYearViewTo];
//		[topYearViewFrom removeFromSuperview];

//		[displayMode==PCalViewModeByMonth?_calYearView:_calMonthView removeFromSuperview];
	}
}

#pragma mark -

- (BOOL)isVisiblePanel {return (_myWindow!=nil && _myWindow.isVisible==YES && _isHidding==NO)?YES:NO; }

- (BOOL)canHidePanelWindow
{
	if (_myWindow==nil)
		return YES;
	if (_myWindow.attachedSheet!=nil || _myWindow.hasModalWindowDoNotClose==YES || _myWindow.isWinDetached==YES)
		return NO;
	if (_calYearView!=nil && [_calYearView terminateEdition]==NO)
		return NO;
	if (_calMonthView!=nil && [_calMonthView terminateEdition]==NO)
		return NO;
	return YES;
}

- (NSSize)windowSizeForDisplayMode:(NSInteger)displayMode
{
	[self prepareContentViewForMode:displayMode];

	if (displayMode==PCalViewModeByYear)
	{
		NSSize cSize=[CalYearView contentSize];
		return NSMakeSize(	cSize.width+CalContentViewBorder*2.0,
											cSize.height+CalContentViewBorder+self.headerView.frame.size.height);
	}

	if (displayMode==PCalViewModeByMonth)
	{
		NSSize cSize=[_calMonthView contentSize];
		return NSMakeSize(	cSize.width+CalContentViewBorder*2.0,
											cSize.height+CalContentViewBorder+self.headerView.frame.size.height);
	}

	return NSZeroSize;
}

- (void)showWindowAt:(NSRect)zone screen:(NSScreen*)screen isDarkStyle:(BOOL)isDarkStyle
{
	if (_isShowing==YES || _isHidding==YES || screen==nil)
		return;

	//[[PCalUserContext shared] updateReduceTransparencyOs];
	
	_isShowing=YES;

	NSInteger displayMode=[PCalUserContext shared].viewMode;
	if (displayMode!=PCalViewModeByYear && displayMode!=PCalViewModeByMonth)
		displayMode=PCalViewModeByYear;

	if (zone.origin.x<0.0)
		zone.origin.x*=-1.0;

	if (_winContView==nil)
	{
		BOOL visual=!NO;
		NSView *contView=nil;
		
		if (visual==NO)
		{
			THBgColorView *simpleView=[[THBgColorView alloc] initWithFrame:self.view.bounds bgColor:[NSColor whiteColor]];
			simpleView.wantsLayer=YES;
			simpleView.layer.cornerRadius=8.0;
			contView=simpleView;
		}
		else
		{
			NSVisualEffectView *veView=[[NSVisualEffectView alloc] initWithFrame:self.view.bounds];
			//visualEffectView.material=isDarkStyle==YES?NSVisualEffectMaterialDark:NSVisualEffectMaterialLight;
			//visualEffectView.appearance=[NSAppearance appearanceNamed:NSAppearanceNameAqua];
	//		visualEffectView.blendingMode=NSVisualEffectBlendingModeBehindWindow;
	//		visualEffectView.state=NSVisualEffectStateActive;
			veView.maskImage=[NSVisualEffectView th_maskImageWithCornerRadius: 10.0];
			veView.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
			//veView.material=NSVisualEffectMaterialPopover;
			
			if ([THOSAppearance isDarkMode]==NO)
			{
				THBgColorView *simpleView=[[THBgColorView alloc] initWithFrame:self.view.bounds bgColor:[NSColor whiteColor]];
				simpleView.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
//				PaneBgView_Simple *simpleView=[[PaneBgView_Simple alloc] initWithFrame:self.view.bounds];
				[veView addSubview:simpleView];
			}

			contView=veView;
		}
		
		[contView addSubview:self.view];

		_winContView=contView;
		_myWindow.contentView=_winContView;
	}

	NSRect visibleRect=screen.visibleFrame;
	NSSize maxSize=[self windowSizeForDisplayMode:PCalViewModeByYear];

	NSSize vSize=[self windowSizeForDisplayMode:displayMode];
	NSRect wFrame=NSMakeRect(0.0,zone.origin.y-vSize.height,vSize.width,vSize.height);

	_showedSens=(zone.origin.x+maxSize.width+WinRightMargin)<(/*visibleRect.origin.x+*/visibleRect.size.width)?'>':'<';
	wFrame.origin.x=zone.origin.x+(_showedSens=='<'?(zone.size.width-wFrame.size.width):0.0);

	if (_myWindow==nil || _myWindow.screen!=screen)
	{
		_myWindow=[[PCalWindow alloc] initWithContentRect:wFrame
																	styleMask:NSWindowStyleMaskBorderless
												  					backing:NSBackingStoreBuffered
																	defer:YES
																	screen:screen];
		_myWindow.hasShadow=YES;
		_myWindow.backgroundColor=[NSColor clearColor];
		_myWindow.opaque=NO;
		_myWindow.delegate=self;
		_myWindow.level=NSStatusWindowLevel; // toujours status level pour eviter comportement fen "normal" sur multi-screen / exposé.
		
		if (_myWindow.contentView!=_winContView)
			_myWindow.contentView=_winContView;

		[self switchViewToDisplayMode:displayMode animated:NO infos:nil];
	}
	else
	{
		wFrame.origin.x+=screen.frame.origin.x;
		wFrame.origin.y+=screen.frame.origin.y;

		[_myWindow setFrame:wFrame display:NO animate:NO];

		if (displayMode==PCalViewModeByMonth)
			[_calMonthView reloadData];
		else
			[_calYearView reloadData];
	}

	_myWindow.alphaValue=0.0;
	//[(NSVisualEffectView*)self.view setTopHeight:PaneTopHeadarSzH];
	[_myWindow makeKeyAndOrderFront:nil];

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
	{
		context.duration=0.20;
		[(NSWindow*)_myWindow.animator setAlphaValue:1.0];
	}
	completionHandler:^
	{
		_isShowing=NO;
		[_myWindow invalidateShadow];
		[_delegator performSelector:@selector(paneViewControllerDidShow:) withObject:self afterDelay:0.0];
	}];
}

- (void)hideWindow:(BOOL)discrete
{
	if (_myWindow==nil || _isHidding==YES || _isShowing==YES)
		return;

	_isHidding=YES;

	[_calYearView willTerminateUI];
	[_calMonthView willTerminateUI];

	[[PCalUserContext shared] synchronize];

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
	{
		context.duration=0.20;
		[(NSWindow*)_myWindow.animator setAlphaValue:0.0];
	}
	completionHandler:^
	{
		[_myWindow orderOut:nil];
		_isHidding=NO; // après le orderOut
		if (discrete==NO)
			[_delegator performSelector:@selector(paneViewControllerDidHide:) withObject:self afterDelay:0.0];
	}];
}

#pragma mark -

- (void)paneTopYearView:(PaneTopYearView*)sender doAction:(NSDictionary*)action
{
	if ([action[@"action"] isEqualToString:@"SWITCH_MODE"]==YES)
	{
		NSInteger mode=[PCalUserContext shared].viewMode==PCalViewModeByMonth?PCalViewModeByYear:PCalViewModeByMonth;
		[self switchToMode:mode infos:@{@"slow":@([action[@"slow"] boolValue])}];
	}
	else if ([action[@"action"] isEqualToString:@"PREV"]==YES)
	{
		if ([PCalUserContext shared].viewMode==PCalViewModeByMonth)
			[_calMonthView performUserRequest:@"PREV_MONTH" infos:nil];
		else
			[_calYearView performUserRequest:@"PREV_YEAR" infos:nil];
	}
	else if ([action[@"action"] isEqualToString:@"NEXT"]==YES)
	{
		if ([PCalUserContext shared].viewMode==PCalViewModeByMonth)
			[_calMonthView performUserRequest:@"NEXT_MONTH" infos:nil];
		else
			[_calYearView performUserRequest:@"NEXT_YEAR" infos:nil];
	}
	else if ([action[@"action"] isEqualToString:@"GO_TODAY"]==YES)
	{
		if ([PCalUserContext shared].viewMode==PCalViewModeByYear)
			[_calYearView performUserRequest:@"CUR_YEAR_RELOAD" infos:nil];
		else if ([PCalUserContext shared].viewMode==PCalViewModeByMonth)
			[_calMonthView performUserRequest:@"CUR_MONTH_RELOAD" infos:nil];
	}
	else if ([action[@"action"] isEqualToString:@"MORE_MENU"]==YES)
	{
		[(THOverLabel*)action[@"sender"] popMenu:[MoreMenu shared].menu isPull:YES];
	}
	else if ([action[@"action"] isEqualToString:@"DETACH"]==YES)
	{
	}
	else if ([action[@"action"] isEqualToString:@"ATTACH"]==YES)
	{
		NSRect zone=[_delegator paneViewControllerStatusItemZone:self];

		NSRect visibleRect=_myWindow.screen.visibleFrame;
		NSRect wFrame=_myWindow.frame;

		_showedSens=(zone.origin.x+wFrame.size.width+WinRightMargin)<(/*visibleRect.origin.x+*/visibleRect.size.width)?'>':'<';
		wFrame.origin.x=zone.origin.x+(_showedSens=='<'?(zone.size.width-wFrame.size.width):0.0);

		[_myWindow setFrame:wFrame display:YES animate:YES];
	}
}

#pragma mark -

- (void)calYearView:(CalYearView*)sender doAction:(NSDictionary*)action
{
	if ([action[@"kind"] integerValue]==1)
		[_delegator paneViewControllerWantsHide:self];
	else if ([action[@"kind"] integerValue]==2)
	{
		PCalMonth *month=action[@"month"];
		THException(month==nil,@"month==nil");

		NSInteger day=[action[@"day"] integerValue];

		NSDictionary *infos=@{@"action":@(1),@"year":@(month.year),@"month":@(month.month),@"day":@(day),@"slow":@([action[@"slow"] boolValue])};
		[self switchViewToDisplayMode:PCalViewModeByMonth animated:YES infos:infos];
	}
	else if ([action[@"kind"] integerValue]==3)
	{
		PCalMonth *year=action[@"year"];
		THException(year==nil,@"year==nil");

		NSInteger month=[PCalUserContext shared].selectedMonth;
//		NSInteger day=[PCalUserContext shared].selectedDay;
		NSDate *today=[NSDate date];
		if (month==0)
			month=[[PCalSource shared].calendar components:NSCalendarUnitMonth fromDate:today].month;
//		if (day==0)
//			day=[[PCalSource shared].calendar components:NSCalendarUnitDay fromDate:today].day;

		NSDictionary *infos=@{@"action":@(1),@"year":@(year.year),@"month":@(month),/*@"day":@(day)*/@"slow":@([action[@"slow"] boolValue])};
		[self switchViewToDisplayMode:PCalViewModeByMonth animated:YES infos:infos];
	}
	else if ([action[@"kind"] integerValue]==4)
		[_delegator paneViewController:self performAction:@{@"kind":@(1),@"date":action[@"date"]}];
	else if ([action[@"kind"] integerValue]==5)
		[_delegator paneViewController:self performAction:@{@"kind":@(2),@"calEvent":action[@"calEvent"]}];
	else if ([action[@"kind"] integerValue]==6)
	{
		PCalYear *year=action[@"year"];
		[_topYearView setTitle:[NSString stringWithFormat:@"%ld",year.year] animated:NO];
	}
}

- (void)calMonthView:(CalMonthView*)monthView doAction:(NSDictionary*)action
{
	if ([action[@"kind"] integerValue]==1)
		[_delegator paneViewControllerWantsHide:self];
	else if ([action[@"kind"] integerValue]==2)
	{
		PCalMonth *month=action[@"month"];
		THException(month==nil,@"month==nil");

		NSDictionary *infos=@{@"action":@(2),@"year":@(month.year),@"slow":@([action[@"slow"] boolValue])};
		[self switchViewToDisplayMode:PCalViewModeByYear animated:YES infos:infos];
	}
	else if ([action[@"kind"] integerValue]==4)
		[_delegator paneViewController:self performAction:@{@"kind":@(1),@"date":action[@"date"]}];
	else if ([action[@"kind"] integerValue]==5)
		[_delegator paneViewController:self performAction:@{@"kind":@(2),@"calEvent":action[@"calEvent"]}];
	else if ([action[@"kind"] integerValue]==6)
	{
		PCalMonth *month=action[@"month"];
		[_topMonthView setTitle:[month displayMonthWithMode:@"m"] animated:NO];
	}
}

- (void)switchToMode:(NSInteger)mode infos:(NSDictionary*)infos // Aussi depuis les NSMenuItems
{
	if (_isShowing==YES || _isHidding==YES || _isSwitching==YES)
		return;

	if (_myWindow==nil || _myWindow.isVisible==NO)
		return;

	if ([PCalUserContext shared].viewMode==mode)
		return;

	if (mode==PCalViewModeByMonth)
		[_calYearView performUserRequest:@"MODE_MONTH" infos:@{@"slow":@([infos[@"slow"] boolValue])}];
	else if (mode==PCalViewModeByYear)
		[_calMonthView performUserRequest:@"MODE_YEAR" infos:@{@"slow":@([infos[@"slow"] boolValue])}];
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
