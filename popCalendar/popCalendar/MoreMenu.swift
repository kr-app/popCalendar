// MoreMenu.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class MoreMenu: NSObject, NSMenuDelegate {
	
	@objc static let shared = MoreMenu()

	@objc var menu: NSMenu!
	
	override init() {
		super.init()
		menu = NSMenu(withTitle: "menu", delegate: self, autoenablesItems: false)
	}
	
	func menuNeedsUpdate(_ menu: NSMenu) {

		menu.removeAllItems()

		menu.addItem(THMenuItem(withTitle: THLocalizedString("About popCalendar…"), block: { () in
			NSApplication.shared.activate(ignoringOtherApps: true)
			NSApplication.shared.orderFrontStandardAboutPanel(nil)
		}))

		menu.addItem(NSMenuItem.separator())
		
		menu.addItem(THMenuItem(withTitle: THLocalizedString("Preferences…"), block: { () in
			PreferencesWindowController.shared.showWindow(nil)
		}))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(THMenuItem(withTitle: THLocalizedString("Quit popCalendar"), block: { () in
			NSApplication.shared.terminate(nil)
		}))

	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
