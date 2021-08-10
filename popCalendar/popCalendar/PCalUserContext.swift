// PCalUserContext.swift

import Foundation

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc enum PCalViewMode: Int { // SERIALISZED
	case byYear = 0
	case byMonth = 1
}

struct PCalIconStyle: OptionSet { // SERIALISZED
	let rawValue: Int
	static let clock = PCalIconStyle(rawValue: 1)
	static let clockUse24Hour = PCalIconStyle(rawValue: 2)
	static let clockShowAmPm = PCalIconStyle(rawValue: 4)
	static let clockShowDay = PCalIconStyle(rawValue: 8)
	static let clockShowDate = PCalIconStyle(rawValue: 16)
	// 32 — smallfont
	static let icon = PCalIconStyle(rawValue: 64)
}

@objc enum PCalEventsDisplayMode: Int { // SERIALISZED
	case uniqueColor = 0
	case notDisplay = 1
	case showColors = 2
}

@objc enum PCalWeekDayDisplayMode: Int { // SERIALISZED
	case normal = 0
	case letter = 1
}

@objc class PCalUserContext: NSObject {
	@objc static let shared = PCalUserContext()

	@objc var viewMode: Int = 0
	@objc var selectedYear: Int = 0
	@objc var selectedMonth: Int = 0
	@objc var selectedDay: Int = 0
	@objc var doNotSelectToday = false
	@objc var lastSelectedCalendarIdentifier: String?

	var iconStyle: PCalIconStyle = .clock
	@objc var excludedCalendars = [String]()
	@objc var yearEventsDisplayMode: Int = 0
	@objc var weekDayDisplayMode: PCalWeekDayDisplayMode = .normal
	@objc var firstWeekDay: NSNumber?
	@objc var monthEventsDisplayMode: Int = 0
	@objc var customClockDateFormat: String?

	@objc var firstAutoExpandEventEditor = false

	private var selectedEventByDate: NSMutableArray?

	override init() {
		super.init()
		self.loadFromUserDefaults()
	}
	
	private func loadFromUserDefaults() {
		let ud = UserDefaults.standard

		viewMode = ud.integer(forKey: "ViewMode")
		selectedYear = ud.integer(forKey: "SelectedYear")
		selectedMonth = ud.integer(forKey: "SelectedMonth")
		selectedDay = ud.integer(forKey: "selectedDay")
		doNotSelectToday = ud.bool(forKey: "doNotSelectToday")
		lastSelectedCalendarIdentifier = ud.string(forKey: "LastSelectedCalendarIdentifier")

		iconStyle = PCalIconStyle(rawValue: ud.integer(forKey: "iconStyle"))
		if iconStyle.rawValue == 0 {
			iconStyle = [.clock, .clockShowDay, .clockShowDate]
		}
		excludedCalendars = ud.object(forKey: "excludedCalendars") as? [String] ?? []
		yearEventsDisplayMode = ud.integer(forKey: "YearEventsDisplayMode")
		firstWeekDay = ud.object(forKey: "PCalUserContext-firstWeekDay") as? NSNumber
		weekDayDisplayMode = PCalWeekDayDisplayMode(rawValue: ud.integer(forKey: "PCalUserContext-weekDayDisplayMode")) ?? .normal
		monthEventsDisplayMode = ud.integer(forKey: "PCalUserContext-monthEventsDisplayMode")
		customClockDateFormat = ud.string(forKey: "PCalUserContext-customClockDateFormat")

//		selectedEventByDate = NSMutableArray(array: ud.array(forKey: "PCalUserContext-selectedEventByDate"))
	}

	@objc func synchronize() {
		let ud = UserDefaults.standard

		ud.set(viewMode, forKey: "ViewMode")
		ud.set(selectedYear, forKey: "SelectedYear")
		ud.set(selectedMonth, forKey: "SelectedMonth")
		ud.set(selectedDay, forKey: "selectedDay")
		ud.set(doNotSelectToday, forKey: "doNotSelectToday")
		ud.set(lastSelectedCalendarIdentifier, forKey: "LastSelectedCalendarIdentifier")

		ud.set(iconStyle.rawValue, forKey: "iconStyle")
		ud.set(excludedCalendars, forKey: "excludedCalendars")
		ud.set(yearEventsDisplayMode, forKey: "YearEventsDisplayMode")
		ud.set(firstWeekDay, forKey: "PCalUserContext-firstWeekDay")
		ud.set(weekDayDisplayMode.rawValue, forKey: "PCalUserContext-weekDayDisplayMode")
		ud.set(monthEventsDisplayMode, forKey: "PCalUserContext-monthEventsDisplayMode")
		ud.set(customClockDateFormat, forKey: "PCalUserContext-customClockDateFormat")

		ud.set(selectedEventByDate, forKey:"PCalUserContext-selectedEventByDate")
		
		ud.synchronize()
	}

	@objc func selectedEventForDate(_ date: PCalDate) -> String? {
/*		if date == nil || date.year <= 0 || date.month <= 0 || date.day <= 0 {
			return nil
		}
	
		let k = [date.year, date.month, date.day].map({ String($0) }).joined(separator: "-")
		
		for s in selectedEventByDate {
			let comps = s.separatedByString("|")
			if (comps.count==2 && [(NSString*)comps[0] isEqualToString:k]==YES)
				return comps[1];
		}*/

		return nil
	}

	@objc func setSelectedEvent(_ event: String?, forDate: PCalDate) {
//		if (date==nil || date.year<=0 || date.month<=0 || date.day<=0)
//			return;
//
//		NSString *k=[NSString stringWithFormat:@"%d-%d-%d",(int)date.year,(int)date.month,(int)date.day];
//		if (event!=nil)
//		{
//			while (_selectedEventByDate.count>25)
//				[_selectedEventByDate removeObjectAtIndex:0];
//			[_selectedEventByDate addObject:[NSString stringWithFormat:@"%@|%@",k,event]];
//			return;
//		}
//
//		for (NSString *s in _selectedEventByDate.copy)
//		{
//			NSArray *comps=[s componentsSeparatedByString:@"|"];
//			if (comps.count==2 && [(NSString*)comps[0] isEqualToString:k]==YES)
//				[_selectedEventByDate removeObject:s];
//		}
	}

	func clockDateFormat(fromIconStyle iconStyle: PCalIconStyle) -> String {
		var format: String!

		if iconStyle.contains(.clockUse24Hour) {
			format = "HH:mm"
		}
		else {
			format = "h:mm"
			if iconStyle.contains(.clockShowAmPm) {
				format! += " a"
			}
		}

		if iconStyle.contains(.clockShowDate) || iconStyle.contains(.clockShowDay) {
			format = " " + format
		}
		if iconStyle.contains(.clockShowDate) {
			format = "d " + format
		}
		if iconStyle.contains(.clockShowDay) {
			format = "EEE " + format
		}

		return format
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
