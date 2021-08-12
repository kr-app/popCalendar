//  PCalSource.swift

import Foundation
import EventKit

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalMonthRelative: NSObject {
	@objc var year: Int = 0
	@objc var month: Int = 0
	
	init(year: Int, month: Int) {
		self.year = year
		self.month = month
	}
}

@objc class PCalMonthDatePosition: NSObject {
	@objc var wPosition: Int = 0
	@objc var hPosition: Int = 0

	init(wPosition: Int, hPosition: Int) {
		self.wPosition = wPosition
		self.hPosition = hPosition
	}
}

@objc enum PCalSourceCalendarListOption: Int {
	case allowNoCalendar = 1
	case noExcluded = 2
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalSource: NSObject {
	@objc static let shared = PCalSource()
	@objc static let sharedOpQueue = OperationQueue()
	@objc static let didChangeNotification = Notification.Name("PCalSourceDidChangeNotification")

	@objc private(set) var calendar: Calendar!
	@objc private(set) var eventStore: EKEventStore!

	@objc class func canCalYear(_ year: Int, month: Int) -> Bool {
		if year < 1 || year > 2500 {
			return false
		}
		if month < 1 || month > 12 {
				return false
		}
		return true
	}

	// MARK: -
	
	override init() {
		super.init()

		self.calendar = Calendar.current
		self.eventStore = EKEventStore()

		NotificationCenter.default.addObserver(self, selector: #selector(eventStoreChanged), name: NSNotification.Name.EKEventStoreChanged, object: self.eventStore)
	}

	// MARK: -

	@objc func eventStoreChanged(_ notification: Notification) {
		performSelector(onMainThread: #selector(mt_eventStoreChanged), with: nil, waitUntilDone: false)
	}

	@objc func mt_eventStoreChanged() {
		NotificationCenter.default.post(name: Self.didChangeNotification, object: self, userInfo: nil)
	}

	// MARK: -

	@objc func hasUserRights() -> Bool {
		if eventStore == nil {
			return false
		}

		let status = EKEventStore.authorizationStatus(for: .event)
		if /*status==EKAuthorizationStatusNotDetermined || */status == .authorized {
			return true
		}
		
		return false
	}

	@objc func requestUserRights() {
		guard let eventStore = eventStore
		else {
			return
		}

		eventStore.requestAccess(to: .event, completion: { (granted: Bool, error: Error?) in
			if granted == false {
				THLogError("granted:\(granted) error:\(error)")
			}
			else {
				THLogInfo("granted:\(granted)")
			}
		})
	}

	// MARK: -

	@objc func sourcesCalendarsWithOptions(_ options: PCalSourceCalendarListOption) -> [[String: Any]] {
		guard let eventStore = eventStore
		else {
			let title = String(format: THLocalizedString("%@ does not have access to your calendars."),THRunningApp.appName)
			return [["kind": -1, "title": title]]
		}
		
		var sourcesCalList = [[String: Any]]()
		var sourcesCalOthers = [[String: Any]]()
		let excludedCalendars = PCalUserContext.shared.excludedCalendars
		
		for source: EKSource in eventStore.sources {

			let calendars = source.calendars(for: .event)
			var theCalendars = [[String: Any]]()

			for calendar: EKCalendar in calendars {
				let calIdentifier = calendar.calendarIdentifier

	//			if ((options&1)!=0 && (calendar.allowsContentModifications==NO || calendar.isImmutable==YES))
	//				continue;

				if (options.rawValue&PCalSourceCalendarListOption.noExcluded.rawValue) != 0 && excludedCalendars.contains(calIdentifier) == true {
					continue
				}

				theCalendars.append(["kind": 2, "calendar": calendar, "title": calendar.title])
			}

			if theCalendars.count == 0 {
				continue
			}

			let sourceType = source.sourceType
			if sourceType == .calDAV || sourceType == .exchange || sourceType == .local || sourceType == .mobileMe {
				sourcesCalList.append(["kind": 1, "source": source, "title": source.title])
				sourcesCalList += theCalendars
			}
			else {
				sourcesCalOthers += theCalendars
			}
		}

		if sourcesCalOthers.count == 0 && (options.rawValue&PCalSourceCalendarListOption.allowNoCalendar.rawValue) != 0 {
			return [["kind": -1, "title": THLocalizedString("No Calendar")]]
		}

		if sourcesCalOthers.count > 0 {
			sourcesCalList.append(["kind": 1, "title": THLocalizedString("Others")])
			sourcesCalList += sourcesCalOthers
		}

		return sourcesCalList
	}

	@objc func hasAtLeastOneFreeCalendar() -> Bool {
		let excludedCalendars = PCalUserContext.shared.excludedCalendars
		for source in self.eventStore.sources {
			let calendars = source.calendars(for: .event)
			for calendar in calendars {
				if excludedCalendars.contains(calendar.calendarIdentifier) == true {
					continue
				}
				if calendar.allowsContentModifications == false {
					continue
				}
				return true
			}
		}
		return false
	}
	
	@objc func calendarsFiltered() -> [EKCalendar] {
	   var allCalendars = [EKCalendar]()
		let excludedCalendars = PCalUserContext.shared.excludedCalendars

		for source in self.eventStore.sources {
			let calendars = source.calendars(for: .event)
			for calendar in calendars {
				if excludedCalendars.contains(calendar.calendarIdentifier) == true {
					continue
				}
				allCalendars.append(calendar)
			}
		}

		return allCalendars
	}

	func firstWeekdayValue() -> Int {
		if let pFirstWeekDay = PCalUserContext.shared.firstWeekDay {
			if pFirstWeekDay > 0 && pFirstWeekDay <= 7 {
				return pFirstWeekDay
			}
		}
		return self.calendar.firstWeekday
	}
	
	@objc func weekDayLabels() -> [String]? {
		let weekDayDisplayMode = PCalUserContext.shared.weekDayDisplayMode
		let dateFormatter = DateFormatter()

		var symbols = [String]()
		if weekDayDisplayMode == .letter {
			for dayLabel in dateFormatter.shortWeekdaySymbols {
				symbols.append((dayLabel as NSString).substring(to: 1).uppercased())
			}
		}
		else {
			for dayLabel in dateFormatter.shortWeekdaySymbols {
				symbols.append(dayLabel.uppercased())
			}
		}

		let symbolIdx = self.firstWeekdayValue() - 1
		if symbolIdx >= symbols.count || symbols.count != 7 {
			return nil
		}

		var dayLabels = (symbols as NSArray).subarray(with: NSRange(symbolIdx, 7 - symbolIdx)) as! [String]
		dayLabels += (symbols as NSArray).subarray(with: NSRange(0, symbolIdx)) as! [String]
		
		return dayLabels
	}

	@objc func eventsWithFirstDate(_ firstDate: Date, lastDate: Date) -> [EKEvent]? {
		THFatalError(self.calendar == nil, "self.calendar == nil")
		THFatalError(self.eventStore == nil, "self.eventStore == nil")

		if firstDate == lastDate {
			THLogError("firstDate == lastDate")
			return nil
		}

		let lastComps = DateComponents(withYear: 0, month: 0, day: 1)
		guard let lastDate = self.calendar.date(byAdding: lastComps, to: lastDate)
		else {
			THLogError("lastDate == nil")
			return nil
		}

		let calendars = calendarsFiltered()
		let predicate = self.eventStore.predicateForEvents(withStart: firstDate, end: lastDate, calendars: calendars)

		let t = CFAbsoluteTimeGetCurrent()
		let events = self.eventStore.events(matching: predicate)
		THLogInfo("requested events in:" + (CFAbsoluteTimeGetCurrent() - t).th_string() + "sec(s)")

		let excludedCalendars = PCalUserContext.shared.excludedCalendars
		var nEvents = [EKEvent]()

		for event in events {
			if excludedCalendars.contains(event.calendar.calendarIdentifier) == true {
				continue
			}
			nEvents.append(event)
		}

		return nEvents
	}

	private func proposedCalendarForEventCreation(fromDate calDate: PCalDate) -> EKCalendar? {

		var allCalendars: [EKCalendar]? = nil
		let excludedCalendars = PCalUserContext.shared.excludedCalendars

		if let lastSelectedCalendarIdentifier = PCalUserContext.shared.lastSelectedCalendarIdentifier {
			allCalendars = self.eventStore.calendars(for: .event).filter({ $0.allowsContentModifications == true })

			for calendar in allCalendars! {
				let calendarId = calendar.calendarIdentifier
				if excludedCalendars.contains(calendarId) == true {
				   continue
				}
				if calendarId == lastSelectedCalendarIdentifier {
				   return calendar
				}
			}
		}

		if let calendars = calDate.eventsCalendars?.filter( { $0.allowsContentModifications == true } ) {
			for calendar in calendars {
				if excludedCalendars.contains(calendar.calendarIdentifier) == true {
					continue
				}
				return calendar
		   }
		}

		if allCalendars == nil {
			allCalendars = self.eventStore.calendars(for: .event).filter({ $0.allowsContentModifications == true })
		}

		for calendar in allCalendars! {
			if excludedCalendars.contains(calendar.calendarIdentifier) == true {
				continue
			}
			return calendar
		}

		return nil
	}
	
	func createCalEvent(fromCalDate calDate: PCalDate?, pError: inout String?) -> PCalEvent? {
		guard 	let calDate = calDate,
					let date = calDate.date
		else {
			return nil
		}
		guard let calendar = proposedCalendarForEventCreation(fromDate: calDate)
		else {
			pError = THLocalizedString("No available Calendar. Please, create an editable calendar from Calendar Application.")
			return nil
		}

		let event = EKEvent(eventStore: self.eventStore)

		let hour = self.calendar.component(.hour, from: Date())
		let startDate = self.calendar.date(byAdding: .hour, value: hour, to: date)?.addingTimeInterval(3600.0) ?? date

		event.calendar = calendar
		event.title = ""
		event.startDate = startDate
		event.endDate = startDate.addingTimeInterval(3600.0)

		let result = PCalEvent(event: event, refDate: calDate.date)
		result.isOnCreation = true

		return result
	}
	
	@objc func removeCalEvent(_ calEvent: PCalEvent) -> String? {
		do {
			try self.eventStore.remove(calEvent.event, span: .thisEvent)
		}
		catch {
			THLogError("remove == false calEvent:\(calEvent)")
			return error.localizedDescription
		}
		return nil
	}

	@objc func saveChangesOfCalEvent(_ calEvent: PCalEvent) -> String? {
		if calEvent.hasChanges == false {
			return nil
		}
		
		do {
			try self.eventStore.save(calEvent.event, span: .thisEvent, commit: true)
		}
		catch {
			THLogError("save == false calEvent:\(calEvent)")
			return error.localizedDescription
		}

		calEvent.hasChanges = false
		calEvent.isOnCreation = false

		return nil
	}

	
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension PCalSource {

	@objc func dateComponentsByChangingKeyboardDirection(_ direction: String, fromCalDate calDate: PCalDate) -> DateComponents? {
		let dayDelta = direction == "t" ? -7 :  direction == "r" ? 1 : direction == "b" ? 7 : direction == "l" ? -1 : 0
		if dayDelta == 0 {
			return nil
		}

		let dateComps = DateComponents(withYear: calDate.year, month: calDate.month, day: calDate.day)
		guard let date = calendar.date(from: dateComps)
		else {
			return nil
		}

		guard let d_date = calendar.date(byAdding: .day, value: dayDelta, to: date)
		else {
			return nil
		}

		return calendar.dateComponents([.year, .month, .day], from: d_date)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
