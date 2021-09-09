// CalEventListContView.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
class CalEventListContView : NSView, NSMenuDelegate {

	weak var parentListView: CalEventListView!
	weak var delegator: CalEventListViewDelegateProtocol!

	override var isFlipped: Bool { true }
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.autoresizingMask = [.width, .minYMargin]
		//	self.menu=[[NSMenu alloc] initWithTitle:@"RightMenu" delegate:self autoenablesItems:NO];
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func hasEvents() -> Bool {
		self.subviews.count > 0
	}

	private func rowViews() -> [CalEventListRowView] {
		self.subviews.filter( { $0 is CalEventListRowView } ) as! [CalEventListRowView]
	}

	func reloadData(withEvents events:[PCalEvent]?, selectedEvent: String?) {
		th_removeAllSubviews()

		let events = events?.sorted(by: { $0.startDate < $1.startDate })
		let dateFormatter = DateFormatter(dateStyle: .none, timeStyle: .short)

		let frameSz = self.frame.size
		var ptY: CGFloat = 0.0

		if let events = events {
			for event in events {
				let rowView = CalEventListRowView(frameRect: NSRect(0.0,ptY,frameSz.width,CalEventListView.rowHeight),
																			event: event,
																			dateFormatter: dateFormatter,
																			delegator: self)
				rowView.autoresizingMask = [.width, .maxYMargin]

				if let selectedEvent = selectedEvent {
					rowView.isSelected = event.eventIdentifier == selectedEvent
				}
		
				addSubview(rowView)
				ptY += rowView.frame.size.height
			}
		}

	//	NSRect svRect=self.enclosingScrollView.frame;
		setFrameSize(NSSize(frameSz.width, ptY))
		scrollToSelectedRowView()

		for rowView in self.subviews {
			rowView.frame = NSRect(rowView.frame.origin.x, rowView.frame.origin.y, self.frame.size.width, rowView.frame.size.height)
		}

	}

	func selectEvent(_ eventId: String?) {
		for rowView in rowViews() {
			rowView.isSelected = eventId != nil && rowView.isEvent(eventId!)
		}
		scrollToSelectedRowView()
	}

	func scrollToSelectedRowView() {
		for rowView in rowViews() {
			if rowView.isSelected {
				enclosingScrollView?.th_scrollTo(visiblePoint: NSPoint(0.0, rowView.frame.origin.y + rowView.frame.size.height))
			}
		}
	}

	//#pragma mark -
	//
	//- (void)mouseDown:(NSEvent*)event
	//{
	//	[self calEventListRowViewSelectionChange:nil infos:nil];
	//}

	//- (void)drawRect:(NSRect)dirtyRect
	//{
	////	[[NSColor greenColor] set];
	////	[NSBezierPath fillRect:self.bounds];
	//}

	//- (void)menuNeedsUpdate:(NSMenu*)menu
	//{
	//	if (menu==self.menu)
	//	{
	//		[menu removeAllItems];
	//		[menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"New Event") target:self action:@selector(mi_newEvent:)]];
	//	}
	//}
	//
	//- (void)mi_newEvent:(NSMenuItem*)sender
	//{
	//	if ([self.delegator calEventListView:self.parentListView canSelectionChange:nil]==YES)
	//	{
	//		[self selectEvent:nil];
	//		[self.delegator calEventListView:self.parentListView wantsNewCalEvent:nil];
	//	}
	//}
}

extension CalEventListContView: CalEventListRowViewDelegateProtocol {
	
	func calEventListRowViewCanChangeSelection(_ sender: CalEventListRowView) -> Bool {
		return delegator.calEventListViewShouldChangeSelection(self.parentListView)
	}

	func calEventListRowView(_ sender: CalEventListRowView, selectionDidChange infos: [String: Any]?) {
		for rowView in self.rowViews() {
			if rowView != sender {
				rowView.isSelected = false
			}
		}

		parentListView.isDoubleClick = infos?["doubleAction"] as? Bool ?? false

		let event = sender.isSelected ? sender.event : nil
		delegator.calEventListView(self.parentListView, didSelectCalEvent: event)
	}

	func calEventListRowViewRevealInCalApp(_ sender: CalEventListRowView) {
		self.delegator.calEventListView(self.parentListView, revealCalEventInCalApp: sender.event)
	}

	func calEventListRowViewWantsDelete(_ sender: CalEventListRowView) {
		self.delegator.calEventListView(self.parentListView, deleteCalEvent:sender.event)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
