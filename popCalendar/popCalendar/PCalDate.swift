//  PCalDate.swift

import Cocoa
import EventKit

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalDate: NSObject {
	@objc private(set) var date: Date!
	@objc private(set) var refMonth: Int = 0

	@objc private(set) var year: Int = 0
	@objc private(set) var month: Int = 0
	@objc private(set) var day: Int = 0

	@objc var hasEvents: Bool { get { events != nil && events!.count > 0 } }

	@objc private(set) var isToday = false
	@objc private(set) var isWeekEnd = false
	@objc private(set) var events: [PCalEvent]?
	@objc private(set) var eventsCalendars:  [EKCalendar]?
	@objc private(set) var eventsCalendarColors: [NSColor]?

	@objc private(set) var attributedStringOfDay: NSAttributedString?
	
	//	NSString *_dayAsString;
	//	const char *_q_dayAsStringC;
	//	int _q_dayAsStringLen;
	//	NSSize _q_dayAsStringSz;
	//	CGFloat _q_dayAsStringColor;

	@objc init(withDate date: Date, refMonth: Int, today: DateComponents, calendar: Calendar) {
		super.init()

		let comps = calendar.dateComponents([.year, .month, .day], from: date)

		self.date = date
		self.refMonth = refMonth

		self.year = comps.year!
		self.month = comps.month!
		self.day = comps.day!

		self.isToday = day == today.day && month == today.month && year == today.year
		self.isWeekEnd = calendar.isDateInWeekend(date)
	}

	//- (void)dealloc
	//{
	//	if (_q_dayAsStringC!=NULL)
	//	{
	//		free((void*)_q_dayAsStringC);
	//		_q_dayAsStringC=NULL;
	//	}
	//}

	override var description: String {
		th_description("year:\(year) month:\(month) day:\(day)")
	}

	@objc func dayAsString() -> String {
		String(day)
	}

	//- (BOOL)getQDayAsStringC:(const char**)pStringC strLen:(int*)pStrLen size:(NSSize*)pSize color:(CGFloat*)pColor mode:(int)mode attrs:(NSDictionary*)attrs
	//{
	//	if (mode==1)
	//	{
	//		NSString *dayAsString=self.dayAsString;
	//
	//		const char *dayStr=[dayAsString cStringUsingEncoding:NSMacOSRomanStringEncoding];
	//		_q_dayAsStringC=strdup(dayStr!=NULL?dayStr:"?");
	//		_q_dayAsStringLen=(int)strlen(_q_dayAsStringC);
	//		_q_dayAsStringSz=[dayAsString sizeWithAttributes:attrs];
	//
	//		NSColor *color=attrs[NSForegroundColorAttributeName];
	//		[color getWhite:&_q_dayAsStringColor alpha:NULL];
	//	}
	//	else if (mode==2)
	//	{
	//		if (_q_dayAsStringC!=NULL)
	//		{
	//			free((void*)_q_dayAsStringC);
	//			_q_dayAsStringC=NULL;
	//		}
	//
	//	}
	//
	//	if (_q_dayAsStringC==NULL)
	//		return NO;
	//
	//	*pStringC=_q_dayAsStringC;
	//	*pStrLen=_q_dayAsStringLen;
	//	*pSize=_q_dayAsStringSz;
	//	*pColor=_q_dayAsStringColor;
	//
	//	return YES;
	//}

	@objc func updateAttributedStringOfDay(withAttrs attrs: [NSAttributedString.Key : Any]?) -> NSAttributedString? {
		attributedStringOfDay = NSAttributedString(string: dayAsString(), attributes: attrs)
		return attributedStringOfDay
	}

	@objc func attributedStringOfDayNeedsUpdate() {
		attributedStringOfDay = nil
	}

	@objc func cleanEvents() {
		events = nil
		eventsCalendars = nil
		eventsCalendarColors = nil
		attributedStringOfDay = nil
	}

	@objc func updateWithEvent(_ event: EKEvent, startDate: TimeInterval, endDate: TimeInterval) {
		let date = self.date!

		let ti = date.timeIntervalSinceReferenceDate;
		let tiNext = ti + 1.0.th_day
		// >= le jour meme
		// < juste avant le prochain jour

		if 	(startDate >= ti && startDate < tiNext) ||
			(endDate > ti && endDate <= tiNext) ||
			(startDate < ti && endDate > tiNext) {

			let calWeekEvent = PCalEvent(event: event, refDate:date)
			if events == nil {
				events = []
			}
			events!.append(calWeekEvent)

			if let calendar = event.calendar {
				let calendarId = calendar.calendarIdentifier
	
				if eventsCalendars == nil {
					eventsCalendars = []
				}

				if eventsCalendars!.contains(where: {$0.calendarIdentifier == calendarId }) == false {
					eventsCalendars!.append(calendar)
					eventsCalendarColors = eventsCalendars!.map({ $0.color })
				}
			}
		}
	}

	@objc func eventWithIdentifier(_ identifier: String) ->  PCalEvent? {
		return events?.first(where: { $0.eventIdentifier == identifier })
	}

	override var hash: Int {
		return day
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		if object == nil {
			return false
		}
		guard let other = object as? Self
		else {
			return false
		}
		if other == self {
			return true
		}
		return year == other.year && month == other.month && day == other.day
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
