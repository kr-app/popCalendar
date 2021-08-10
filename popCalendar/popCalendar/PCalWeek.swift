//  PCalWeek.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalWeek : NSObject {
	@objc private(set) var dates: [PCalDate]!
	@objc private(set) var firstWeekday: Int = 0
	@objc private(set) var weekOfYear: Int = 0
	
	@objc class func weekLineIndexOfDate(_ date: Date, firstDayOfWeek: Int, calendar: Calendar) -> Int {
		if firstDayOfWeek < 0 || firstDayOfWeek > 7 {
			return -1
		}
		let weekday = calendar.component(.weekday, from: date)
		if weekday == firstDayOfWeek {
			return 0
		}
		if weekday > firstDayOfWeek {
			return weekday - firstDayOfWeek
		}
		if weekday < firstDayOfWeek {
			return 7 - (firstDayOfWeek - weekday)
		}
		return -1
	}

	@objc class func calWeekLinesOfYear(_ year: Int, month: Int, today: DateComponents, calendar: Calendar, firstWeekday: Int) -> [PCalWeek]? {
		if PCalSource.canCalYear(year, month: month) == false {
			THLogError("canCalYear == false")
			return nil
		}

		let firstDayComps = DateComponents(withYear: year, month: month, day: 1)
		guard let firstDayDate = calendar.date(from: firstDayComps)
		else {
			THLogError("firstDayDate")
			return nil
		}

		let firstDatePosition = weekLineIndexOfDate(firstDayDate, firstDayOfWeek: firstWeekday, calendar: calendar)
		if firstDatePosition == -1 {
			THLogError("firstDatePosition == -1")
			return nil
		}

		var dates: [PCalDate]?

		for i in 0..<firstDatePosition {
			let date = calendar.date(byAdding: .day, value: -1 * (i + 1), to: firstDayDate)!
			let wlDate = PCalDate(withDate: date, refMonth: month, today: today, calendar: calendar)
			if dates == nil {
				dates = []
			}
			dates!.insert(wlDate, at: 0)
		}

		var results = [PCalWeek]()

		var i = 0
		while true {
			guard let date = calendar.date(byAdding: .day, value: i, to: firstDayDate)
			else {
				THLogError("date == nil")
				return nil
			}
			
			let wlDate = PCalDate(withDate: date, refMonth: month, today: today, calendar: calendar)
			if dates == nil {
				if wlDate.month != firstDayComps.month {
					break
				}
				dates = []
			}

			dates!.append(wlDate)
			if dates!.count == 7 {
				results.append(PCalWeek(withDates: dates!, firstWeekday: firstWeekday))
				dates = nil
			}

			i += 1
		}

		return results
	}

	@objc init(withDates dates: [PCalDate], firstWeekday: Int) {
		super.init()
	
		self.dates = dates
		self.firstWeekday = firstWeekday
	}

	override var description: String {
		th_description("dates:\(dates)")
	}

	@objc func calDateWithYear(_ year: Int, month: Int, day: Int) -> PCalDate? {
		return dates.first(where: { $0.year == year && $0.month == month && $0.day == day })
	}

	@objc func updateWeekOfYearWithCalendar(_ calendar: Calendar) {
		THFatalError(dates == nil || dates!.count != 7, "incorrect dates, dates:\(dates)")
		self.weekOfYear = calendar.component(.weekOfYear, from: self.dates.first!.date)
	}

	//- (BOOL)containsDateWithPCalDateRepresentation:(PCalDateRepresentation*)calWeekDateRepresentation
	//{
	//	if (calWeekDateRepresentation==nil)
	//		return NO;
	//	for (PCalDate *weekDate in _weekDates)
	//		if (weekDate.day==calWeekDateRepresentation.day && weekDate.month==calWeekDateRepresentation.month && weekDate.year==calWeekDateRepresentation.year)
	//			return YES;
	//	return NO;
	//}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
