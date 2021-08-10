// PreferencesWindowController.swift

import Cocoa
import EventKit

//--------------------------------------------------------------------------------------------------------------------------------------------
class CalendarCheckBoxCell : NSButtonCell {
	var calColor: NSColor?
	
	override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
		guard let calColor = self.calColor
		else {
			return
		}

	//	NSImage *img=[[NSImage alloc] initWithSize:cellFrame.size];
	//	[img lockFocus];
		super.draw(withFrame: cellFrame, in: controlView)
	//	[img unlockFocus];
	//
	//	[img drawInRect:cellFrame];

		calColor.withAlphaComponent(0.5).set()
	//	NSRectFillUsingOperation(NSMakeRect(cellFrame.origin.x+6.0,cellFrame.origin.y+3.0,12.0,12.0),NSCompositeSourceAtop);
		NSBezierPath(		roundedRect: NSRect(	cellFrame.origin.x + 2.0,
																			cellFrame.origin.y + 2.0,
																			cellFrame.size.width - 3.0 * 2.0,
																			cellFrame.size.height - 4.0),
									xRadius: 4.0, yRadius: 4.0).fill()
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------
fileprivate class SourceCaltem {
	var kind: Int!
	var title: String?
	var checked = false
	var calendar: EKCalendar?

	init(kind: Int, title: String?, checked: Bool = false, calendar: EKCalendar? = nil) {
		self.kind = kind
		self.title = title
		self.checked = checked
		self.calendar = calendar
	}
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@objc protocol PreferencesWindowControllerDelegatorProtocol: AnyObject {
	@objc func preferencesWindowController(_ sender: Any, didChange: [String: Any]?)
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PreferencesWindowController: PreferencesWindowControllerObjc,
																		NSTableViewDataSource, NSTableViewDelegate,
																		THNSChecboxTableCellViewProtocol {

	@objc static let shared = PreferencesWindowController(windowNibName: "PreferencesWindowController")

	@IBOutlet var relaunchOnLoginButton: NSButton!
	@IBOutlet var hotKeyButton: NSButton!
	@IBOutlet var hotKeyField: THHotKeyFieldView!
	@IBOutlet var iconAsClockButton: NSButton!
	@IBOutlet var iconClockOptionsButton: NSButton!
	@IBOutlet var customClockOptionsWindowController: PreferencesClockOptionsWindowController!
	@IBOutlet var calendarsTableView: NSTableView!

	@objc weak var delegator: PreferencesWindowControllerDelegatorProtocol!

	private var sourceCalList: [SourceCaltem]?

	override func windowDidLoad() {
		super.windowDidLoad()

		self.window!.title = THLocalizedString("popCalendar Preferences")

		delegator = NSApplication.shared.delegate as! PreferencesWindowControllerDelegatorProtocol

		let hotKey = THHotKeyRepresentation.fromUserDefaults()
		hotKeyButton.state = (hotKey != nil && hotKey!.isEnabled == true) ? .on : .off
		hotKeyField.setControlSize(hotKeyButton.controlSize)
		hotKeyField.setChangeObserver(self,
																keyCode: hotKey?.keyCode ?? 0,
																modifierFlags: hotKey?.modifierFlags ?? 0,
																isEnabled: hotKey?.isEnabled ?? false)
	
		iconAsClockButton.state = .on
		iconAsClockButton.isEnabled = false
		iconClockOptionsButton.isEnabled = iconAsClockButton.state == .on
	}

	// MARK: -

	@objc func windowDidBecomeMain(_ notification: Notification) {
		updateUILoginItem()
	}

	override func showWindow(_ sender: Any?) {
		let _ = self.window
		
		updateUILoginItem()
		updateUISourceCal()
		
		super.showWindow(sender)
	}

	// MARK: -

	func updateUILoginItem() {
		relaunchOnLoginButton.state = THAppInLoginItem.loginItemStatus()
	}

	func updateUISourceCal() {
		var sourceCalList = [SourceCaltem]()

		for source in PCalSource.shared.sourcesCalendarsWithOptions(.allowNoCalendar) {
			let kind = source["kind"] as! Int
			let title = source["title"] as! String

			if kind == 2 {
				let cal = source["calendar"] as! EKCalendar
				let checked = PCalUserContext.shared.excludedCalendars.contains(cal.calendarIdentifier) == true
				sourceCalList.append(SourceCaltem(kind: kind, title: title, checked: checked, calendar: cal))
			}
			else {
				sourceCalList.append(SourceCaltem(kind: kind, title: title))
			}
		}

		self.sourceCalList = sourceCalList
		calendarsTableView.reloadData()
	}

	// MARK: -

	func numberOfRows(in tableView: NSTableView) -> Int {
		return sourceCalList != nil ? sourceCalList!.count : 0
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let sourceCal = sourceCalList![row]

		let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell_id"), owner: self) as! THNSChecboxTableCellView

		cell.checkedBox.state = sourceCal.checked ? .on : .off
		(cell.checkedBox.cell as! CalendarCheckBoxCell).calColor = sourceCal.calendar?.color
		cell.textField!.objectValue = sourceCal.title
//		cell.imageView!.image = sourceCal.icon

		return cell
	}

	func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
		let sourceCal = sourceCalList![row]
		return sourceCal.kind == 1
	}
	
	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
		let sourceCal = sourceCalList![row]
		return sourceCal.kind == 2
	}

	func checboxTableCellView(_ sender: THNSChecboxTableCellView, didCheck check: Bool, at row: Int) {
		let sourceCal = sourceCalList![row]

		if sourceCal.kind == 2 {
			let calendarId = sourceCal.calendar!.calendarIdentifier

			var excludedCalendars = PCalUserContext.shared.excludedCalendars
			if check {
				excludedCalendars.append(calendarId)
			}
			else {
				excludedCalendars.removeAll(where: { $0 == calendarId })
			}
			
			PCalUserContext.shared.excludedCalendars = excludedCalendars
			delegator.preferencesWindowController(self, didChange: ["kind": 1])
		}
	}

	// MARK: -
	
	@IBAction func relaunchOnLoginButtonAction(_ sender: NSButton) {
		THAppInLoginItem.setIsLoginItem(sender.state == .on)
		updateUILoginItem()
	}

	@IBAction func hotKeyButtonAction(_ sender: NSButton) {
		self.hotKeyField.setIsEnabled(sender.state == .on)
	}
	
	@IBAction func changeAction(_ sender: NSButton) {
		if sender == iconClockOptionsButton {
			customClockOptionsWindowController.delegator = delegator
			customClockOptionsWindowController.beginAsForWindow(sender.window!)
		}
	}

	// MARK: -

	func hotKeyFieldView(_ sender: THHotKeyFieldView!, didChangeWithKeyCode keyCode: UInt, modifierFlags: UInt, isEnabled: Bool) -> Bool {
		THHotKeyRepresentation(keyCode: keyCode, modifierFlags: modifierFlags, isEnabled: isEnabled).saveToUserDefaults()
		
		if isEnabled == true {
			return THHotKeyCenter.shared().registerHotKey(withKeyCode: keyCode, modifierFlags: modifierFlags, tag: 1)
		}

		return THHotKeyCenter.shared().unregisterHotKey(withTag: 1)
	}
	
}
//--------------------------------------------------------------------------------------------------------------------------------------------
