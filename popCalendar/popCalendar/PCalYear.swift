// PCalYear.swift

import Foundation
import EventKit

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc protocol PCalYearDelegateProtocol: AnyObject {
	@objc func calYearDidUpdateEvents(_ sender: PCalYear)
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalYear : NSObject {
	private var source: PCalSource!
	private weak var delegate: PCalYearDelegateProtocol?
	private var _updateEventsJeton: Int = 0
	
	@objc private(set) var months: [PCalMonth]?
	@objc private(set) var isCurrentYear = false
	@objc private(set) var year: Int = 0

	@objc init(withSource source: PCalSource, year: Int, delegate: PCalYearDelegateProtocol?) {
		super.init()

		var year = year
		
		if year == 0 || PCalSource.canCalYear(year, month: 1) == false {
			year = source.calendar.component(.year, from: Date())
		}

		self.source = source
		self.year = year
		self.delegate = delegate
	}

	override var description: String {
		th_description("year:\(year)")
	}

	@objc func todayCalDate() -> PCalDate? {
		guard let months = months
		else {
			return nil
		}
	
		for month in months {
			let weekDate = month.todayCalDate()
			if weekDate != nil && weekDate!.isToday == true {
				return weekDate
			}
		}

		return nil
	}

	@objc func calDateWithYear(_ year: Int, month: Int, day: Int) -> PCalDate? {
		if year == 0 || month == 0 || day == 0 {
			return nil
		}

		guard let months = months
		else {
			return nil
		}

		for m in months {
			if let date = m.calDateWithYear(year, month: month, day: day) {
				return date
			}
		}

		return nil
	}

	@objc func updateData() {
		THFatalError(year == 0, "year == 0")

		let currentYear = source.calendar.component(.year, from: Date())

		if months == nil || months!.count != 12 {
			var months = [PCalMonth]()
			for _ in 0..<12 {
				months.append(PCalMonth(source: source))
			}
			self.months = months
		}

		for i in 0..<12 {
			let month = months![i]
			month.setYear(year, month: i + 1)
			month.updateWeeks()
		}

		isCurrentYear = currentYear == year ? true : false
	}

	@objc func updateEventsInBackground(_ inBackground: Bool) {
		guard let months = months
		else {
			THLogError("months")
			return
		}
	
		guard 	let firstMonth = months.first,
					let lastMonth = months.last,
					let firstWeek = firstMonth.weeks?.first,
					let lastWeek = lastMonth.weeks?.last
		else {
			THLogError("firstMonth | lastMonth | firstWeek | lastWeek")
			return
		}

		guard 	let firstDate = firstWeek.dates.first?.date,
					let lastDate = lastWeek.dates.last?.date
		else {
			THLogError("firstDate || lastDate")
			return
		}
		
		let jeton = _updateEventsJeton + 1
		_updateEventsJeton = jeton

		if inBackground == true {
			let op = BlockOperation(block: { () in
#if DEBUG
	//					[NSThread sleepForTimeInterval:2];
#endif

						let events = self.source.eventsWithFirstDate(firstDate, lastDate: lastDate)

						DispatchQueue.main.async {
							self.updateEvents(jeton: jeton, events: events)
						}
					})
			//op.threadPriority=1.0;
			PCalSource.sharedOpQueue.addOperation(op)
		}
		else {
			let events = source.eventsWithFirstDate(firstDate, lastDate: lastDate)
			months.forEach({ $0.updateWithEvents(events) })
		}
	}

	private func updateEvents(jeton: Int, events: [EKEvent]?) {
		if jeton != _updateEventsJeton {
			THLogInfo("skipped update events from background because jeton:\(jeton) / \(_updateEventsJeton)")
			return
		}

		months?.forEach({ $0.updateWithEvents(events) })

		delegate?.calYearDidUpdateEvents(self)
	}

	private func getYear(fromRelativeYear relativeYear: Int) -> Int {
		guard let calendar = source.calendar
		else {
			return -1
		}

		guard let date = calendar.date(from: DateComponents(withYear: self.year, month: 1, day: 1))
		else {
			return -1
		}

		guard let nDate = calendar.date(byAdding: .year, value: relativeYear, to: date)
		else {
			return -1
		}

		let year = calendar.component(.year, from: nDate)
		if PCalSource.canCalYear(year, month: 1) == false {
			return -1;
		}

		return year
	}

	@objc func updateYear(_ year: Int) {
		if PCalSource.canCalYear(year, month: 1) == false {
			return
		}
		self.year = year
	}

	@objc func switchToRelativeYear(_ year: Int) {
		let nYear = getYear(fromRelativeYear: year)
		if nYear == -1 {
			return
		}
		updateYear(nYear)
	}

	@objc func switchToToday() {
		self.year = source.calendar.component(.year, from: Date())
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
