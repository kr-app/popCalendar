// PCalEventReveal.swift

import Cocoa
import EventKit

//--------------------------------------------------------------------------------------------------------------------------------------------
class PCalEventReveal : NSObject {

	private var event_id: String!
	private var event_sd: Date!
	private var event_ed: Date!
	private var event_title: String! // informatif

	private var _query: NSMetadataQuery?
	private var _qStartDate: Date?

	init?(event: EKEvent) {
		super.init()

		guard 	let event_id = event.eventIdentifier,
					let event_sd = event.startDate,
					let event_ed = event.endDate,
					let event_title = event.title
		else {
			THLogError("event_id | event_sd | event_ed | event_title")
			return nil
		}
		
		//sharedUID dans la descript de EKEvent : corresponde ) l'id du ficher

		self.event_id = event_id
		self.event_sd = event_sd
		self.event_ed = event_ed
		self.event_title = event_title
	}

	deinit {
		terminateQuery()
	}

	// MARK: -

	func startRevealing() -> Bool {
		THFatalError(Thread.isMainThread == false, "should be executed from the main thread only")

		if _query != nil {
			return false
		}

		//	NSMetadataItem *mdItem=[[NSMetadataItem alloc] initWithURL:[NSURL fileURLWithPath:@"/Users/michaelparrot/Library/Calendars/69A1F831-EB63-4553-855F-8C95AFC87C2F.caldav/09BE4131-E724-4E67-A7A9-A4356F77700D.calendar/Events/22BAF706-E4BC-4CFB-BF95-A4C30E15FE84.ics"]];
		//	NSString *contentType=[mdItem valueForAttribute:(NSString*)kMDItemContentType];

		let predicate = NSPredicate(format: "(%K == %@) && (%K == %@)",
								kMDItemContentType as String, "com.apple.ical.ics.event",
								kMDItemTitle as String, event_title)

		_query = NSMetadataQuery()
		_query!.predicate = predicate
		_query!.searchScopes = [NSMetadataQueryUserHomeScope]

		if _query!.start() == false {
			THLogError("start == false")
			return false
		}

		_qStartDate = Date()
		NotificationCenter.default.addObserver(self, selector:#selector(n_queryDidFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object:_query)

		return true
	}

	private func terminateQuery() {
		if _query == nil {
			return
		}

		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: _query)
		_query?.stop()
		_query = nil
	}

	func stop() {
		terminateQuery()
	}

	// MARK: -

	@objc func n_queryDidFinishGathering(_ notification: Notification) {
		guard let query = _query
		else {
			return
		}

		let resultCount = query.resultCount

		THLogInfo("eventId:\(event_id), event:\(event_title) resultCount:\(resultCount)")

		for i in 0..<resultCount {
			guard let mdItem = query.result(at: i) as? NSMetadataItem
			else {
				continue
			}

			//NSString *uuId=[mdItem valueForAttribute:kMDItemAuthors];
			guard let path = mdItem.value(forAttribute: kMDItemPath as String) as? String
			else {
				continue
			}

			guard let icsFile = PCalEventIcsFile(withFile: path)
			else {
				THLogError("icsFile==nil path:\(path)")
				continue
			}

			guard 	let sd = icsFile.startDate,
						let ed = icsFile.endDate
			else {
				THLogError("sd || ed == nil icsFile:\(icsFile)")
				continue
			}

			if sd == event_sd && ed == event_ed {
				if NSWorkspace.shared.open(URL(fileURLWithPath: path)) == false {
					THLogError("open == false path:\(path)")
				}
				break
			}
		}

		terminateQuery()
		THLogError("event file not found, event:\(event_title)")
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
