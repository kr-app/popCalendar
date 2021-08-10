// PCalMonth.swift

import Cocoa
import EventKit

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalMonth : NSObject {
	private static let monthSymbols = DateFormatter().monthSymbols!

	@objc private(set) var source: PCalSource!

	@objc private(set) var year: Int = 0
	@objc private(set) var month: Int = 0

	@objc private(set) var  weeks: [PCalWeek]?
	@objc private(set) var isCurrentMonth = false

	private var displayMonthTitles = [String: String]()

	@objc init(source: PCalSource) {
		super.init()

		self.source = source
	}

	override var description: String {
		th_description("year:\(year) month:\(month)")
	}

	@objc func displayMonthWithMode(_ mode: String) -> String? {
		if month == 0 || year == 0 {
			return nil
		}

		if let d = displayMonthTitles[mode] {
			return d
		}
	
		let monthSymbols = Self.monthSymbols

		let monthIdx = month - 1
		if  monthIdx >= monthSymbols.count {
			return nil
		}

		if mode == "Y" {
			displayMonthTitles[mode] = monthSymbols[monthIdx].uppercased()
		}
		else {
			displayMonthTitles[mode] = monthSymbols[monthIdx].capitalized + " " + String(year)
		}

		return displayMonthTitles[mode]
	}

	@objc func todayCalDate() -> PCalDate? {
		guard let weeks = weeks
		else {
			return nil
		}

		for week in weeks {
			if let date = week.dates.first(where: { $0.isToday }) {
				return date
			}
		}
	
		return nil
	}

	@objc func calDateWithDateComponents(_ dateComponents: DateComponents) -> PCalDate? {
		guard let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day
		else {
			return nil
		}
		return calDateWithYear(year, month: month, day: day)
	}

	@objc func calDateWithYear(_ year: Int, month: Int, day: Int) -> PCalDate? {
		if year == 0 || month == 0 || day == 0 {
			return nil
		}

		guard let weeks = weeks
		else {
			return nil
		}

		for week in weeks {
			if let date = week.calDateWithYear(year, month: month, day: day) {
				return date
			}
		}
	
		return nil
	}

	@objc func calDateWeekWithYear(_ year: Int, month: Int, day: Int) -> PCalWeek? {
		if year == 0 || month == 0 || day == 0 {
			return nil
		}

		guard let weeks = weeks
		else {
			return nil
		}
		
		for week in weeks {
			if week.calDateWithYear(year, month: month, day: day) != nil {
				return week
			}
		}
	
		return nil
	}

	@objc func getPositionOfDateWithYear(_ year: Int, month: Int, day: Int) -> PCalMonthDatePosition {
		if year == 0 || month == 0 || day == 0 {
			return PCalMonthDatePosition(wPosition: -1, hPosition: -1)
		}

		guard let weeks = weeks
		else {
			return PCalMonthDatePosition(wPosition: -1, hPosition: -1)
		}

		var hPosition = 0
		for week in weeks {
			var wPosition = 0
			for date in week.dates {
				if date.day == day && date.month == month && date.year == year {
					return PCalMonthDatePosition(wPosition: wPosition, hPosition: hPosition)
				}
				wPosition += 1
			}
			hPosition += 1
		}

		return PCalMonthDatePosition(wPosition: -1, hPosition: -1)
	}

	@objc func updateWeeks() {
		THFatalError(year == 0, "year == 0")
		THFatalError(month == 0, "month == 0")

		let calendar = source.calendar!
		let todayComps = calendar.dateComponents([.year, .month, .day], from: Date())

		guard let weeks = PCalWeek.calWeekLinesOfYear(year, month: month, today: todayComps, calendar: calendar, firstWeekday: source.firstWeekdayValue())
		else {
			THLogError("calWeekLinesOfYear year:\(year) month:\(month) todayComps:\(todayComps)")
			return
		}
		
		self.weeks = weeks
		self.isCurrentMonth = todayComps.year == year && todayComps.month == month
		displayMonthTitles.removeAll()
	}

	@objc func updateWeeksAndMonthEvents() {
		updateWeeks()
		updateEvents()
	
		guard let weeks = weeks
		else {
			return
		}

		let calendar = source.calendar!
		for week in weeks {
			week.updateWeekOfYearWithCalendar(calendar)
		}
	}

	@objc func updateEvents() {
		if weeks?.count == 0 {
			THLogError("weeks.count == 0")
		}

		let firstWeek = weeks?.first
		let lastWeek = weeks?.last

		guard 	let firstDate = firstWeek?.dates.first,
					let lastDate = lastWeek?.dates.last
		else {
			THLogError("events == nil")
			return
		}
	
		let events = source.eventsWithFirstDate(firstDate.date, lastDate: lastDate.date)
		if events == nil {
			THLogError("events == nil")
		}
	
		updateWithEvents(events)
	}

	@objc func updateWithEvents(_ events: [EKEvent]?) {
		weeks?.forEach({ $0.dates.forEach({ $0.cleanEvents() }) })

		guard let events = events, let weeks = weeks
		else {
			return
		}
	
		for event in events {
			guard 	let startDate = event.startDate,
						let endDate = event.endDate
			else {
				THLogError("startDate == nil || endDate == nil event:\(event)")
				continue
			}

			let startDateTI = startDate.timeIntervalSinceReferenceDate
			let endDateTI = endDate.timeIntervalSinceReferenceDate

			for week in weeks {
				for weekDate in week.dates {
					weekDate.updateWithEvent(event, startDate: startDateTI, endDate: endDateTI)
				}
			}
		}

	}

	@objc func yearAndMonthFromRelativeMonth(_ month: Int) -> PCalMonthRelative {
		let calendar = source.calendar!

		guard let date = calendar.date(from: DateComponents(withYear: year, month: self.month, day: 1))
		else {
			return PCalMonthRelative(year: 0, month: 0)
		}
	
		guard let nDate = calendar.date(byAdding: .month, value: month, to: date)
		else {
			return PCalMonthRelative(year: 0, month: 0)
		}

		let comps = calendar.dateComponents([.year, .month], from: nDate)
		return PCalMonthRelative(year: comps.year!, month: comps.month!)
	}

	@objc func setYear(_ year: Int, month: Int) {
		self.year = year
		self.month = month
		weeks = nil
	}

	@objc func switchToRelativeMonth(_ month: Int) {
		let yearAndMonth = yearAndMonthFromRelativeMonth(month)
		if yearAndMonth.year == 0 && yearAndMonth.month == 0 {
			return
		}
		setYear(yearAndMonth.year, month: yearAndMonth.month)
	}

	@objc func switchToToday() {
		let calendar = source.calendar!
		let comps = calendar.dateComponents([.year, .month], from: Date())

		year = comps.year!
		month = comps.month!
		weeks = nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
