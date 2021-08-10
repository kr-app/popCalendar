//  PCalUserInterration.swift

import Cocoa
import EventKit

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalUserInterration: NSObject {

	@objc static let shared = PCalUserInterration()
	
	private var eventReveal: PCalEventReveal?
	
	@objc class func openCalendarApp(_ completion: ((Bool) -> Void)?) {
		guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal")
		else {
			if let completion = completion {
				completion(false)
			}
			return
		}

		let config = NSWorkspace.OpenConfiguration()
		NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: {( app: NSRunningApplication?, error: Error?) in
			if app == nil || error != nil {
				THLogError("openApplication url:\(url) error:\(error)")
			}

			if let completion = completion {
				DispatchQueue.main.async {
					completion((app != nil && error == nil) ? true : false)
				}
			}
		})
	}

	@objc class func showDateInCalendarApp(_ date: Date?) {
		guard let dateComps = date == nil ? nil : Calendar.current.dateComponents([.year, .month, .day], from: date!)
		else {
			return
		}
		
		openCalendarApp( {(ok: Bool) in
			if ok == false {
				THLogError("openCalendarApp date:\(date)")
				return
			}

			let source = """
									tell application \"Calendar\"\n
										activate\n
										view calendar at date \"\(dateComps.day)/\(dateComps.month)/\(dateComps.year)\"\n
									end tell\n
								"""

			let script = NSAppleScript(source: source)

			var errorInfo: NSDictionary?
			if script?.executeAndReturnError(&errorInfo) == nil {
				THLogError("executeAndReturnError == nil errorInfos:\(errorInfo)")
			}
		})
	}

	@objc func revealEventInCalendarApp(_ event: EKEvent) {
		eventReveal?.stop()
		eventReveal = nil

		PCalUserInterration.openCalendarApp( {(ok: Bool) in
			if ok == false {
			   THLogError("openCalendarApp event:\(event)")
			   return
		   }

			let eventReveal = PCalEventReveal(event: event)
			if eventReveal == nil || eventReveal!.startRevealing() == false {
				THLogError("eventRevealSearch event:\(event)")
				return
			}

			self.eventReveal = eventReveal
		})
	}

	@objc class func performCreateEventForDate(_ date: PCalDate, calSource: PCalSource, window: NSWindow) -> PCalEvent? {
		if calSource.hasAtLeastOneFreeCalendar() == false {
			let title = THLocalizedString("Empty Calendar List")
			let msg = THLocalizedString("Please, use Calendar Application to create a least one calendar.")

			let alert = NSAlert(withTitle: title, message: msg, buttons: ["Ok", THLocalizedString("Open Calendar App")])
			alert.beginSheetModal(for: window, completionHandler: {(response: NSApplication.ModalResponse) in
				if response == .alertSecondButtonReturn {
					self.openCalendarApp(nil)
				}
			})

			return nil
		}

		var error: String? = nil
		if let calEvent = calSource.createCalEvent(fromCalDate: date, pError: &error) {
			return calEvent
		}

		let title = THLocalizedString("Unable to Create New Event.")
		let msg = (error as String?) ?? THLocalizedString("Please, use Calendar Application.")

		let alert = NSAlert(withTitle: title, message: msg, buttons: ["Ok", THLocalizedString("Open Calendar App")])
		alert.beginSheetModal(for: window, completionHandler: {(response: NSApplication.ModalResponse) in
			if response == .alertSecondButtonReturn {
				self.openCalendarApp(nil)
			}
		})

		return nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
