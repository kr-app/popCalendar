// EventEditorViewController.m

#import "EventEditorViewController.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@interface EventEditorBgView : NSView
{
	BOOL _drawTopLine;
	NSString *_msg;
	BOOL _isDarkStyle;
}

@end

@implementation EventEditorBgView

- (void)setDrawTopLine:(BOOL)drawTopLine
{
	if (drawTopLine==_drawTopLine)
		return;
	_drawTopLine=drawTopLine;
	[self setNeedsDisplay:YES];
}

- (void)setMessage:(NSString*)message isDarkStyle:(BOOL)isDarkStyle
{
	if (message==_msg)
		return;
	_msg=message;
	_isDarkStyle=isDarkStyle;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
//	[[NSColor orangeColor] th_drawInRect:self.bounds];

//	if (_drawTopLine==YES)
//	{
//		NSSize frameSz=self.frame.size;
//		[[NSColor colorWithCalibratedWhite:0.8 alpha:_isDarkStyle==YES?0.25:1.0] set];
//		[NSBezierPath fillRect:NSMakeRect(0.0,frameSz.height-1.0,frameSz.width,1.0)];
//	}

	if (_msg!=nil)
	{
		NSSize frameSz=self.frame.size;

		NSColor *color=[NSColor colorWithCalibratedWhite:_isDarkStyle==YES?1.0:0.5 alpha:1.0];
		NSDictionary *attrs=@{NSFontAttributeName:[NSFont systemFontOfSize:13.0],NSForegroundColorAttributeName:color};

		NSSize sz=[_msg sizeWithAttributes:attrs];
		sz=NSMakeSize(CGFloatCeil(sz.width),CGFloatCeil(sz.height));
		[_msg drawAtPoint:NSMakePoint(CGFloatFloor((frameSz.width-sz.width)/2.0),CGFloatFloor((frameSz.height-sz.height)/2.0)) withAttributes:attrs];
	}
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
//@implementation EventEditorClickectTextField
//
//- (void)mouseDown:(NSEvent*)event
//{
//	if (self.isEnabled==YES && theEvent!=nil && theEvent.clickCount>0)
//		[self.clickDelegator performSelector:@selector(eventEditorClickectTextFieldClicked:) withObject:self];
//	[super mouseDown:theEvent];
//}
//
//@end
//--------------------------------------------------------------------------------------------------------------------------------------------
		

//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation EventEditorViewController

- (PCalDate*)calDate { return _calDate; }
- (PCalEvent*)calEvent { return _calEvent; }

- (id)initWithDelegator:(id)delegator
{
	if (self=[super initWithNibName:[self className] bundle:nil])
		_delegator=delegator;
	return self;
}

- (void)setDrawTopLine:(BOOL)drawTopLine
{
	[(EventEditorBgView*)self.view setDrawTopLine:drawTopLine];
}

//- (void)setAlwaysCancelButton:(BOOL)alwaysCancelButton { _alwaysCancelButton=alwaysCancelButton; }

- (void)loadView
{
	[super loadView];

	[self.view setFrameSize:self.contentView.frame.size];
	[self.contentView setFrameOrigin:NSZeroPoint];
	[self.view addSubview:self.contentView];

	self.calendarsOverView.menu=[[NSMenu alloc] initWithTitle:@"calendars-menu" delegate:self autoenablesItems:NO];
	self.alertMsgPopMenu.menu.delegate=self;

	[(THNSTextViewPlaceHolder*)self.notesTextView setPhInset:NSMakePoint(0.0, -2.0)];
	self.notesTextView.font=[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeRegular]];
}

- (BOOL)terminateEdition:(NSWindow*)mainWindow completion:(void (^)(BOOL isOk))bkCompletion
{
	if (_calDate==nil || _calEvent==nil)
		return YES;
	if (_calEvent.hasChanges==NO)
		return YES;
	if (_isUserCancelling==YES)
		return NO;

	_isUserCancelling=YES;
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
//	[(PCalWindow*)mainWindow setHasModalWindowDoNotClose:YES];

	NSString *title=nil;
	if (_calEvent.title.length>0)
		title=THLocalizedStringFormat(@"Do you want to save the changes made to \"%@\"?",_calEvent.title);
	else
		title=THLocalizedString(@"Do you want to save the changes made to the event?");

	NSString *msg=THLocalizedString(@"Your changes will be lost if you don’t save them.");

	NSArray *buttons=@[	THLocalizedString(@"Save"),
										THLocalizedString(@"Cancel"),
										THLocalizedString(@"Don't Save")];

	NSAlert *alert=[[NSAlert alloc] initWithTitle:title message:msg buttons:buttons];
	[alert beginSheetModalForWindow:mainWindow completionHandler:^(NSModalResponse response)
	{
		_isUserCancelling=NO;
//		[(PCalWindow*)mainWindow setHasModalWindowDoNotClose:NO];

		if (response==NSAlertFirstButtonReturn)
		{
			if ([self performEndEdition:1]==YES)
				if (bkCompletion!=NULL)
					bkCompletion(YES);
		}
		else if (response==NSAlertThirdButtonReturn)
		{
			[_calEvent cancelChanges];
			if (bkCompletion!=NULL)
				bkCompletion(YES);
		}
	}];

	return NO;
}

#pragma mark -

- (void)updateUIWithCalDate:(PCalDate*)calDate calEvent:(PCalEvent*)calEvent calSource:(PCalSource*)calSource
{
	NSArray *sourcesCalendars=[calSource sourcesCalendarsWithOptions:PCalSourceCalendarListOptionNoExcluded];

	if (calDate==nil)
	{
		calEvent=nil;
		sourcesCalendars=nil;
	}

	[self view];

	_calSource=calSource;
	_calDate=calDate;
	_calEvent=calEvent;

	[self.contentView setHidden:(calDate==nil || calEvent==nil)?YES:NO];
	if (calDate!=nil && calEvent!=nil)
		[(EventEditorBgView*)self.view setMessage:nil isDarkStyle:_isDarkStyle];
	else if (calDate!=nil && calDate.events.count>0)
		[(EventEditorBgView*)self.view setMessage:THLocalizedString(@"No Selected Event") isDarkStyle:_isDarkStyle];
	else if (calDate!=nil)
		[(EventEditorBgView*)self.view setMessage:THLocalizedString(@"No Event") isDarkStyle:_isDarkStyle];
	else
		[(EventEditorBgView*)self.view setMessage:THLocalizedString(@"No Selected Date") isDarkStyle:_isDarkStyle];

	if (self.contentView.isHidden==YES)
		return;

	EKEvent *event=calEvent.event;
	BOOL editable=(event!=nil && event.calendar!=nil && event.calendar.allowsContentModifications==YES)?YES:NO;
	BOOL allDay=event.allDay;

	[self updateUITitleField:calEvent];

	if (calEvent.isOnCreation==YES)
	{
		[self.titleField selectText:nil];
		[self.titleField.window makeFirstResponder:self.titleField];
	}

	_hasCalendars=[self updateUISourcesCalendars:sourcesCalendars calendarIdentifier:event.calendar.calendarIdentifier];
	_isEditable=editable;

	self.allDayButton.state=allDay==YES?NSControlStateValueOn:NSControlStateValueOff;
	[self updateUIDatePickers:allDay startDate:event.startDate endDate:event.endDate];

	[self updateUIParticipantsparticipants:event.attendees requestCnStore:YES];
	[self updateUIAlarms:event.alarms isEditable:editable];

	NSString *location=event.location;
	self.locationField.stringValue=location!=nil?location:@"";
	self.locationField.toolTip=location;

	NSString *url=event.URL.absoluteString;
	self.urlField.stringValue=url!=nil?url:@"";
	self.urlField.toolTip=url;

	NSString *notes=event.notes;
	while (1)
	{
		if (notes.length<5 || [notes rangeOfString:@"\n" options:0 range:NSMakeRange(0, 1)].location==NSNotFound)
			break;
		notes=[notes substringFromIndex:1];
	}
	self.notesTextView.string=notes!=nil?notes:@"";

	[self setHasChanges:NO];

	[self.titleField setEnabled:editable];
	[self.allDayButton setEnabled:editable];
	[self.fromDatePicker setEnabled:editable];
	[self.toDatePicker setEnabled:editable];

	[self.locationField setEditable:editable];
	[self.urlField setEditable:editable];
	[self.notesTextView setEditable:editable];

	[self.calendarsOverView setIsDisabled:(_hasCalendars==YES && self.titleField.isEnabled==YES)?NO:YES];

	if (_isDarkStyle==YES)
	{
		NSDictionary *attrs=@{NSFontAttributeName:self.locationField.font,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]};
		[(NSTextFieldCell*)self.locationField.cell setPlaceholderAttributedString:[[NSAttributedString alloc] initWithString:THLocalizedString(@"Location_None") attributes:attrs]];
		[(NSTextFieldCell*)self.urlField.cell setPlaceholderAttributedString:[[NSAttributedString alloc] initWithString:THLocalizedString(@"URL_None") attributes:attrs]];
		[(THNSTextViewPlaceHolder*)self.notesTextView th_setPlaceHolder:THLocalizedString(@"Notes_None") withAttrs:attrs];
	}
	else
	{
		[(NSTextFieldCell*)self.locationField.cell setPlaceholderString:THLocalizedString(@"Location_None")];
		[(NSTextFieldCell*)self.urlField.cell setPlaceholderString:THLocalizedString(@"URL_None")];

		NSDictionary *attrs=@{NSFontAttributeName:self.locationField.font,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.67 alpha:1.0]};
		[(THNSTextViewPlaceHolder*)self.notesTextView th_setPlaceHolder:THLocalizedString(@"Notes_None") withAttrs:attrs];
	}
}

- (void)updateUI
{
	[self updateUIWithCalDate:_calDate calEvent:_calEvent calSource:_calSource];
}

- (void)updateUITitleField:(PCalEvent*)calEvent
{
	NSString *pH=THLocalizedString((calEvent!=nil && calEvent.isOnCreation==YES)?@"New Event":@"Event Title");

	if (_isDarkStyle==YES)
	{
		NSDictionary *attrs=@{NSFontAttributeName:self.titleField.font,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]};
		[(NSTextFieldCell*)self.titleField.cell setPlaceholderAttributedString:[[NSAttributedString alloc] initWithString:pH attributes:attrs]];
	}
	else
		[(NSTextFieldCell*)self.titleField.cell setPlaceholderString:pH];

	self.titleField.stringValue=calEvent.title!=nil?calEvent.title:@"";
}

- (BOOL)updateUISourcesCalendars:(NSArray*)sourcesCalendars calendarIdentifier:(NSString*)calendarIdentifier
{
	NSMenu *calendarMenu=self.calendarsOverView.menu;
	[calendarMenu removeAllItems];

	EKCalendar *selectedCal=nil;
	NSUInteger calCount=0;

	for (NSDictionary *sourceCalendar in sourcesCalendars)
	{
		if ([sourceCalendar[@"kind"] integerValue]==1)
		{
			if (calendarMenu.numberOfItems>0)
				[calendarMenu addItem:[NSMenuItem separatorItem]];
			[calendarMenu addItem:[NSMenuItem th_menuItemWithTitle:sourceCalendar[@"title"] tag:0 isEnabled:NO]];
		}
		else if ([sourceCalendar[@"kind"] integerValue]==2)
		{
			EKCalendar *calendar=sourceCalendar[@"calendar"];
			THException(calendar==nil,@"calendar==nil");

			BOOL isSelectable=NO;
			if (calendar.allowsContentModifications==YES)
				isSelectable=YES;
			else if (calendarIdentifier!=nil && [calendarIdentifier isEqualToString:calendar.calendarIdentifier]==YES)
				isSelectable=YES;

			NSSize badgeSize=NSMakeSize(16.0,10.0);
			NSImage *badge=[[NSImage alloc] initWithSize:badgeSize];
			[badge lockFocus];
			{
				[[NSColor colorWithCalibratedWhite:_isDarkStyle==YES?0.75:0.2 alpha:1.0] set];
				[NSBezierPath fillRect:NSMakeRect(0.0,0.0,badgeSize.width,badgeSize.height)];

				[calendar.color set];
				[NSBezierPath fillRect:NSMakeRect(1.0,1.0,badgeSize.width-1.0*2.0,badgeSize.height-1.0*2.0)];
			}
			[badge unlockFocus];

			NSMenuItem *menuItem=[NSMenuItem th_menuItemWithTitle:calendar.title target:self action:@selector(mi_calendars:) representedObject:calendar isEnabled:isSelectable];
			menuItem.image=badge;
			[calendarMenu addItem:menuItem];

			if (selectedCal==nil && [calendarIdentifier isEqualToString:calendar.calendarIdentifier]==YES)
			{
				selectedCal=calendar;
				menuItem.state=NSControlStateValueOn;
			}

			calCount+=1;
		}
	}

	self.calendarsOverView.repInfo=selectedCal;
	[self.calendarsOverView setNeedsDisplay:YES];

	return calCount>0?YES:NO;
}

- (void)updateUIDatePickers:(BOOL)isAllDay startDate:(NSDate*)startDate endDate:(NSDate*)endDate
{
	self.fromDatePicker.datePickerElements=isAllDay==YES?(NSDatePickerElementFlagYearMonthDay):(NSDatePickerElementFlagYearMonthDay|NSDatePickerElementFlagHourMinute);
	self.toDatePicker.datePickerElements=self.fromDatePicker.datePickerElements;

	[self.fromDatePicker sizeToFit];
	[self.toDatePicker sizeToFit];

	if (isAllDay==YES && endDate!=nil)
		endDate=[endDate dateByAddingTimeInterval:-1.0];

	self.fromDatePicker.dateValue=startDate!=nil?startDate:_calEvent.refDate;
	self.toDatePicker.dateValue=endDate!=nil?endDate:_calEvent.refDate;
}

- (void)updateUIParticipantsparticipants:(NSArray*)participants requestCnStore:(BOOL)requestCnStore
{
	NSMutableArray *rParticipants=[NSMutableArray array];

	NSMutableArray *dedupNames=[NSMutableArray array];
	for (EKParticipant *participant in participants)
	{
		NSString *name=participant.name;
		if (name!=nil)
		{
			if ([dedupNames containsObject:name]==YES)
				continue;
			[dedupNames addObject:name];
		}
		[rParticipants addObject:participant];
	}

	[rParticipants sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];

	[self.inviteesPopUpMenu removeAllItems];

	if (rParticipants.count==0)
	{
		[self.inviteesPopUpMenu addItemWithTitle:THLocalizedString(@"Nobody")];
	}
	else
	{
		if (rParticipants.count>1)
			[self.inviteesPopUpMenu addItemWithTitle:THLocalizedStringFormat(@"%d participants",(int)rParticipants.count)];

		CNContactStore *cnStore=nil;

		CNAuthorizationStatus status=[CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
		if (requestCnStore==YES && status==CNAuthorizationStatusNotDetermined)
		{
			[[[CNContactStore alloc] init] requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError *error)
			{
				if (granted==YES)
					[self updateUIParticipantsparticipants:participants requestCnStore:NO];
			}];
		}
		else if (status==CNAuthorizationStatusAuthorized)
			cnStore=[[CNContactStore alloc] init];
		
		int i=0;
		
		for (EKParticipant *participant in rParticipants)
		{
			EKParticipantRole r=participant.participantRole;
		//	EKParticipantRoleUnknown,
		//	EKParticipantRoleRequired,
		//	EKParticipantRoleOptional,
		//	EKParticipantRoleChair,
		//	EKParticipantRoleNonParticipant

			NSString *title=participant.name;
		
			if (title!=nil && title.length>0)
			{
				if (r==EKParticipantRoleChair)
					title=[title stringByAppendingFormat:@" (%@)",THLocalizedString(@"Chair")];
				else if (r==EKParticipantRoleRequired)
					title=[title stringByAppendingFormat:@" (%@)",THLocalizedString(@"Required")];
			}

			if (title==nil || title.length==0)
				title=THLocalizedStringFormat(@"Participant %d",(++i));
	
			[self.inviteesPopUpMenu addItemWithTitle:title];
			
			NSString *url=participant.URL.absoluteString;
			if (url!=nil && [url hasPrefix:@"mailto:"]==YES)
				self.inviteesPopUpMenu.lastItem.toolTip=[url substringFromIndex:@"mailto:".length];

//			CNContact *contact=nil;
//			if (cnStore!=nil)
//			{
//				NSPredicate *pred=participant.contactPredicate;
//				NSArray *keys=@[CNContactIdentifierKey,CNContactThumbnailImageDataKey];
//				NSError *error=nil;
//				NSArray *contacts=pred==nil?nil:[cnStore unifiedContactsMatchingPredicate:pred keysToFetch:keys error:&error];
//				contact=contacts.count==1?contacts[0]:nil;
//			}

		}
	}

	[self.inviteesPopUpMenu selectItemAtIndex:0];
	[self.inviteesPopUpMenu setEnabled:rParticipants.count>0?YES:!NO];
}

- (void)updateUIAlarms:(NSArray*)alarms isEditable:(BOOL)isEditable
{
	[self.alertMsgPopMenu removeAllItems];
	EKAlarm *alarmMsg=nil;

	if (alarms.count==0)
		[self.alertMsgPopMenu addItemWithTitle:THLocalizedString(@"None_F")];
	else if (alarms.count==1)
	{
		NSString *title=nil;
		EKAlarm *alarm=alarms.lastObject;
	
		if (alarm.type==EKAlarmTypeDisplay)
		{
			alarmMsg=alarm;
			title=THLocalizedStringFormat(@"Message (%@)",[PCalEvent relativeDelayOffSetOfAlarm:alarm]);
		}
		else if (alarm.type==EKAlarmTypeAudio)
			title=THLocalizedStringFormat(@"Play %@ (%@)",alarm.soundName,[PCalEvent relativeDelayOffSetOfAlarm:alarm]);
		else if (alarm.type==EKAlarmTypeProcedure)
			title=THLocalizedStringFormat(@"Open (%@)",[PCalEvent relativeDelayOffSetOfAlarm:alarm]);
		else if (alarm.type==EKAlarmTypeEmail)
			title=THLocalizedStringFormat(@"Send e-mail to %@ (%@)",alarm.emailAddress,[PCalEvent relativeDelayOffSetOfAlarm:alarm]);
		else
			title=THLocalizedStringFormat(@"Alarm (%d)",(int)alarm.type);

		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"None") tag:1 representedObject:nil]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem separatorItem]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:title tag:2 representedObject:nil]];
		[self.alertMsgPopMenu selectItemAtIndex:2];
	}
	else
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedStringFormat(@"%d alerts",(int)alarms.count) tag:3 representedObject:nil]];

	[self.alertMsgPopMenu setEnabled:(isEditable==YES && alarms.count<=1)?YES:NO];

	if (self.alertMsgPopMenu.isEnabled==YES)
	{
		#warning "ne pas utiliser time interval"
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem separatorItem]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"At the time of event") tag:1 representedObject:@(0)]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"5 minutes before") tag:1 representedObject:@(-5*TH_MIN)]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"10 minutes before") tag:1 representedObject:@(-10*TH_MIN)]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"15 minutes before") tag:1 representedObject:@(-15*TH_MIN)]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"30 minutes before") tag:1 representedObject:@(-30*TH_MIN)]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"1 hour before") tag:1 representedObject:@(-1*TH_HOUR)]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"2 hours before") tag:1 representedObject:@(-2*TH_HOUR)]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"1 day before") tag:1 representedObject:@(-1*TH_DAY)]];
		[self.alertMsgPopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"2 days before") tag:1 representedObject:@(-2*TH_DAY)]];

		if (alarmMsg!=nil)
		{
			NSTimeInterval relativeOffset=alarmMsg.relativeOffset;
			for (NSMenuItem *menuItem in self.alertMsgPopMenu.itemArray)
			{
				if (menuItem.tag!=1 || menuItem.representedObject==nil || [menuItem.representedObject doubleValue]!=relativeOffset)
					continue;

				[self.alertMsgPopMenu removeItemAtIndex:1];
				[self.alertMsgPopMenu removeItemAtIndex:1];
				[self.alertMsgPopMenu selectItem:menuItem];
				break;
			}
		}
	}
}

#pragma mark -

- (void)overView:(THOverView*)sender drawRect:(NSRect)rect withState:(THOverViewState)state
{
	if (sender==self.calendarsOverView)
	{
		NSSize bbSz=NSMakeSize(12.0,12.0);
		NSRect bbRect=NSMakeRect(	CGFloatFloor((rect.size.width-bbSz.width)/2.0),
															CGFloatFloor((rect.size.height-bbSz.height)/2.0),
															bbSz.width-0.0*2.0,
															bbSz.height-0.0*2.0);
		EKCalendar *cal=sender.repInfo;

		if (cal==nil)
		{
			[[NSColor colorWithCalibratedWhite:0.5 alpha:1.0] set];
			[[NSBezierPath bezierPathWithOvalInRect:bbRect] stroke];
		}
		else
		{
			if (state==THOverViewStateHighlighted || state==THOverViewStatePressed)
			{
				[[NSColor colorWithCalibratedWhite:0.2 alpha:1.0] set];
				[[NSBezierPath bezierPathWithOvalInRect:bbRect] fill];
			}

			[cal.color set];
			NSSize bSz=NSMakeSize(10.0,10.0);
			[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(	CGFloatFloor((rect.size.width-bSz.width)/2.0),
																										CGFloatFloor((rect.size.height-bSz.height)/2.0),
																										bSz.width,bSz.height)] fill];
		}
	}
	else if (sender==self.saveOView || sender==self.cancelOView)
	{
		NSParagraphStyle *paragraphStyle=[NSParagraphStyle th_paragraphStyleWithAlignment:NSTextAlignmentCenter];
		NSFont *font=[NSFont fontWithName:@"Stencil" size:16];

		NSColor *color=[NSColor colorWithCalibratedWhite:_isDarkStyle==YES?0.75:0.5 alpha:1.0];
		if (state==THOverViewStateHighlighted)
			color=[NSColor colorWithCalibratedWhite:_isDarkStyle==YES?1.0:0.33 alpha:1.0];
		else if (state==THOverViewStatePressed)
			color=[NSColor colorWithCalibratedWhite:_isDarkStyle==YES?0.75:0.1 alpha:1.0];

		NSDictionary *attrs=@{	NSFontAttributeName:font!=nil?font:[NSFont systemFontOfSize:16],
												NSForegroundColorAttributeName:color,
												NSParagraphStyleAttributeName:paragraphStyle};
	
		[sender==self.cancelOView?@"✕":@"✓" drawInRect:NSMakeRect(0.0,0.0,rect.size.width,rect.size.height-0.0*2.0) withAttributes:attrs];
	}
}

- (void)overView:(THOverView*)sender didPressed:(NSDictionary*)infos
{
	if (sender==self.calendarsOverView)
		[sender popMenu:sender.menu isPull:YES];
	else if (sender==self.saveOView)
		[self performEndEdition:1];
	else if (sender==self.cancelOView)
		[self performEndEdition:0];
}

#pragma mark -

- (void)setHasChanges:(BOOL)hasChanges
{
	if (hasChanges==YES)
		_calEvent.hasChanges=YES;

	BOOL canSave=(_hasCalendars==YES && _isEditable==YES && _calEvent!=nil && hasChanges==YES)?YES:NO;
	[self.cancelOView setHidden:(/*_alwaysCancelButton==YES ||*/ canSave==YES)?NO:YES];
	[self.saveOView setHidden:canSave==YES?NO:YES];
}

- (void)mi_calendars:(NSMenuItem*)sender
{
	EKEvent *event=_calEvent.event;
	EKCalendar *calendar=sender.representedObject;

	if (event.calendar.calendarIdentifier!=nil && [event.calendar.calendarIdentifier isEqualToString:calendar.calendarIdentifier]==YES)
		return;

	[PCalUserContext shared].lastSelectedCalendarIdentifier=calendar.calendarIdentifier;
	event.calendar=calendar;

	for (NSMenuItem *menuItem in self.calendarsOverView.menu.itemArray)
		menuItem.state=menuItem==sender?NSControlStateValueOn:NSControlStateValueOff;
	self.calendarsOverView.repInfo=calendar;
	[self.calendarsOverView setNeedsDisplay:YES];

	[self setHasChanges:YES];
}

- (void)controlTextDidChange:(NSNotification*)notification
{
	NSTextField *sender=notification.object;

	if (sender==self.titleField)
		_calEvent.event.title=sender.stringValue;
	else if (sender==self.locationField)
		_calEvent.event.location=sender.stringValue;
	else if (sender==self.urlField)
		_calEvent.event.URL=sender.stringValue.length>0?[NSURL URLWithString:sender.stringValue]:nil;

	[self setHasChanges:YES];
}

- (void)textDidChange:(NSNotification*)notification
{
	id sender=notification.object;
	if (sender==self.notesTextView)
		_calEvent.event.notes=self.notesTextView.string;
	[self setHasChanges:YES];
}

- (IBAction)changeAction:(id)sender
{
	EKEvent *event=_calEvent.event;

	if (sender==self.titleField)
	{
		if (self.saveOView.hidden==NO)
			[self performEndEdition:1];
		return;
	}
	else if (sender==self.allDayButton)
	{
		event.allDay=self.allDayButton.state==NSControlStateValueOn?YES:NO;
		
		if (event.allDay==YES)
		{
			NSCalendar *calendar=[NSCalendar currentCalendar];

			NSDate *startDate=event.startDate;
			if (startDate==nil)
				startDate=_calEvent.refDate;
			NSDateComponents *startDateComp=[calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:startDate];
			startDate=[calendar dateFromComponents:startDateComp];

			NSDate *endDate=event.endDate;
			if (endDate==nil)
				endDate=_calEvent.refDate;
			NSDateComponents *dateComp=[calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:startDate toDate:endDate options:0];
			if (dateComp.day<1)
				dateComp.day=1;
			endDate=[calendar dateByAddingComponents:dateComp toDate:startDate options:0];

			event.startDate=startDate;
			event.endDate=endDate;
		}

		[self updateUIDatePickers:event.allDay startDate:event.startDate endDate:event.endDate];
	}
	else if (sender==self.fromDatePicker)
	{
		NSDate *date=self.fromDatePicker.dateValue;

		NSTimeInterval delta=[event.endDate timeIntervalSinceDate:event.startDate];

		event.startDate=date;
		event.endDate=[date dateByAddingTimeInterval:delta];

		[self updateUIDatePickers:event.allDay startDate:event.startDate endDate:event.endDate];
	}
	else if (sender==self.toDatePicker)
	{
		NSDate *date=self.toDatePicker.dateValue;
		if (event.isAllDay==YES)
			date=[date dateByAddingTimeInterval:1.0];

		NSComparisonResult comp=[date compare:event.startDate];
		if (comp==NSOrderedAscending || comp==NSOrderedSame)
		{
			self.toDatePicker.dateValue=event.startDate;
			return;
		}

		event.endDate=date;

		[self updateUIDatePickers:event.allDay startDate:event.startDate endDate:event.endDate];
	}
/*	else if (sender==self.alertMsgPopMenu)
	{
		if (self.alertMsgPopMenu.selectedItem.tag!=1)
			return;

// a finir faire +/- via calendar, voir alarmWithAbsoluteDate
//		NSNumber *relativeOffset=self.alertMsgPopMenu.selectedItem.representedObject;
//		_calEvent.event.alarms=relativeOffset!=nil?@[[EKAlarm alarmWithRelativeOffset:relativeOffset.doubleValue]]:nil;
	}*/
	else
		return;

	[self setHasChanges:YES];
}

- (BOOL)performEndEdition:(NSInteger)action
{
	id firstResponder=self.view.window.firstResponder;
	if (firstResponder!=nil && [firstResponder isKindOfClass:[NSView class]]==YES && [(NSView*)firstResponder isDescendantOf:self.view]==YES)
		[self.view.window makeFirstResponder:nil];

	BOOL isOk=NO;
	NSDictionary *errorInfo=nil;

	/*if (action==-1)
		isOk=[_delegator eventEditorViewController:self terminateEdition:@"delete" errorInfo:&errorInfo];
	else */if (action==1)
	{
		if (_calEvent!=nil && _calEvent.title.length==0)
		{
			_calEvent.event.title=THLocalizedString(@"New Event");
			[self updateUITitleField:_calEvent];
		}

		if (_calEvent!=nil && [_calEvent canSaveEvent]!=nil)
			isOk=NO;
		else
			isOk=[_delegator eventEditorViewController:self terminateEdition:@"save" errorInfo:&errorInfo];
	}
	else
		isOk=[_delegator eventEditorViewController:self terminateEdition:@"cancel" errorInfo:&errorInfo];

	if (isOk==NO)
	{
		NSString *title=errorInfo[@"title"];
		NSString *error=errorInfo[@"error"];

		if (title==nil)
			title=THLocalizedString(@"Unknow error");

		if ([self.view.window isKindOfClass:[PCalWindow class]]==YES)
		{
			NSAlert *alert=[[NSAlert alloc] initWithTitle:[title th_terminatingBy:@"."] message:[error th_terminatingBy:@"."]];
			[alert beginSheetModalForWindow:self.view.window completionHandler:NULL];
		}
	}

	if (isOk==YES)
		[self setHasChanges:NO];

	return isOk;
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
