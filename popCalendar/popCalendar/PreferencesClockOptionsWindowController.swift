// PreferencesClockOptionsWindowController.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class PrefClockDateFormatField : NSTextField {
	var canAcceptsFirstResp = false

	override var acceptsFirstResponder: Bool { canAcceptsFirstResp }
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class PreferencesClockOptionsWindowController : NSWindowController {

	@IBOutlet var use24HourButton: NSButton!
	@IBOutlet var showAmPmButton: NSButton!
	@IBOutlet var showDayButton: NSButton!
	@IBOutlet var showDateButton: NSButton!
	@IBOutlet var udDateFormat: PrefClockDateFormatField!
	@IBOutlet var udDateFormatHelpButton: NSButton!
	@IBOutlet var okButton: NSButton!

	weak var delegator: PreferencesWindowControllerDelegatorProtocol!

	func beginAsForWindow(_ parentWindow: NSWindow) {
		self.window!.makeFirstResponder(nil)
		udDateFormat.canAcceptsFirstResp = false

		updateUI()
		parentWindow.beginSheet(self.window!, completionHandler: nil)
		perform(#selector(showDel), with: nil, afterDelay: 0.5)
	}

	@objc func showDel() {
		udDateFormat.canAcceptsFirstResp = true
	}

	func clotureSheet() {
		self.window!.sheetParent!.endSheet(self.window!)
		self.window!.orderOut(nil)
	}

	func updateUI() {
		let style = PCalUserContext.shared.iconStyle
		
		use24HourButton.state = style.contains(.clock) && style.contains(.clockUse24Hour) ? .on : .off
		showAmPmButton.state = style.contains(.clock) && style.contains(.clockShowAmPm) ? .on : .off
		showDayButton.state = style.contains(.clock) && style.contains(.clockShowDay) ? .on : .off
		showDateButton.state = style.contains(.clock) && style.contains(.clockShowDate) ? .on : .off

		let clockDateFormat = PCalUserContext.shared.customClockDateFormat
		udDateFormat.stringValue = clockDateFormat ?? PCalUserContext.shared.clockDateFormat(fromIconStyle: style)

		updateUI_Buttons()
	}

	private func updateUI_Buttons() {
		showAmPmButton.isEnabled = use24HourButton.state == .off
	}

	@IBAction func changeAction(_ sender: NSButton) {

		if sender == udDateFormatHelpButton {
			let g = "https://www.google.fr/search?q=NSDateFormatter+format"
			NSWorkspace.shared.open(URL(string: g)!)
			return
		}
		else if sender == okButton {
			clotureSheet()
			return
		}

		updateUI_Buttons()

		var style = PCalIconStyle.clock

		if use24HourButton.state == .on {
			style.insert(.clockUse24Hour)
		}
		if showAmPmButton.state == .on {
			style.insert(.clockShowAmPm)
		}
		if showDayButton.state == .on {
			style.insert(.clockShowDay)
		}
		if showDateButton.state == .on {
			style.insert(.clockShowDate)
		}

		if sender == use24HourButton || sender == showAmPmButton || sender == showDayButton || sender == showDateButton {
			PCalUserContext.shared.customClockDateFormat = nil
			udDateFormat.stringValue = PCalUserContext.shared.clockDateFormat(fromIconStyle: style)
		}
	
		PCalUserContext.shared.iconStyle = style
		delegator.preferencesWindowController(self, didChange: ["kind": 2])
	}

	@IBAction func changeDateFormatter(_ sender: PrefClockDateFormatField) {
		let df = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
		PCalUserContext.shared.customClockDateFormat = df.isEmpty == false ? df : nil

		delegator.preferencesWindowController(self, didChange: ["kind": 2])
	}

	@objc func controlTextDidChange(_ notification: Notification) {
		if let sender = notification.object as? PrefClockDateFormatField {
			if sender == udDateFormat {
				changeDateFormatter(sender)
			}
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
