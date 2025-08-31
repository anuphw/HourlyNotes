#!/usr/bin/swift
//
// HourlyNotes.swift
// Native macOS menu bar app for hourly activity tracking
// No external dependencies - pure Swift/Cocoa
//

import Cocoa
import UserNotifications
import Foundation
import ServiceManagement


// MARK: - Main App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?
    var settings = UserSettings()
    var lastCheckTime: Date?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.title = "📝"
            button.action = #selector(showMenu)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Request notification permissions
        requestNotificationPermissions()
        
        // Setup sleep/wake notifications
        setupSleepWakeNotifications()
        
        // Start hourly timer
        startHourlyTimer()
        
        // Load settings
        settings.load()
        
        // Sync launch at login state with system
        syncLaunchAtLoginState()
        
        // Check for missed hours on startup
        checkForMissedHours()
    }
    
    @objc func showMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Add Note Now", action: #selector(addNoteNow), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        
        let eodItem = NSMenuItem(title: settings.isEOD ? "Resume Notifications ✓" : "EOD (End of Day)", 
                                action: #selector(toggleEOD), keyEquivalent: "e")
        menu.addItem(eodItem)
        
        menu.addItem(NSMenuItem(title: "Today's Summary", action: #selector(showSummary), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    @objc func addNoteNow() {
        showNoteDialog()
    }
    
    func showNoteDialog() {
        let alert = NSAlert()
        alert.messageText = "Hourly Check-in"
        alert.informativeText = "What did you do in the last hour?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        // Create main container view
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 180))
        
        // Get recent notes for context
        let recentNotes = getRecentNotes(limit: 2)
        var yOffset: CGFloat = 180
        
        // Add recent notes section if available
        if !recentNotes.isEmpty {
            let recentLabel = NSTextField(labelWithString: "Recent activity:")
            recentLabel.font = NSFont.boldSystemFont(ofSize: 11)
            recentLabel.textColor = NSColor.secondaryLabelColor
            recentLabel.frame = NSRect(x: 0, y: yOffset - 15, width: 400, height: 15)
            containerView.addSubview(recentLabel)
            yOffset -= 20
            
            for note in recentNotes {
                let noteText = "[\(note.time)] \(note.text)"
                let truncatedText = String(noteText.prefix(80)) + (noteText.count > 80 ? "..." : "")
                
                let noteLabel = NSTextField(labelWithString: truncatedText)
                noteLabel.font = NSFont.systemFont(ofSize: 10)
                noteLabel.textColor = NSColor.tertiaryLabelColor
                noteLabel.frame = NSRect(x: 10, y: yOffset - 15, width: 380, height: 15)
                noteLabel.lineBreakMode = .byTruncatingTail
                containerView.addSubview(noteLabel)
                yOffset -= 18
            }
            
            // Add separator line
            let separator = NSBox(frame: NSRect(x: 0, y: yOffset - 5, width: 400, height: 1))
            separator.boxType = .separator
            containerView.addSubview(separator)
            yOffset -= 10
        }
        
        // Add input field
        let textField = NSTextView(frame: NSRect(x: 0, y: 0, width: 400, height: yOffset - 10))
        textField.isEditable = true
        textField.isSelectable = true
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.isAutomaticQuoteSubstitutionEnabled = false
        textField.isRichText = false
        
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: yOffset - 10))
        scrollView.documentView = textField
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        containerView.addSubview(scrollView)
        alert.accessoryView = containerView
        
        // Focus on the text field
        DispatchQueue.main.async {
            textField.becomeFirstResponder()
        }
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let text = textField.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                saveNote(text)
                showNotification(title: "Note Saved", body: String(text.prefix(50)))
            }
        }
    }
    
    func saveNote(_ text: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let noteEntry = "\(timestamp) | \(text)\n"
        
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let notesURL = homeURL.appendingPathComponent(".notes.txt")
        
        do {
            if let data = noteEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: notesURL.path) {
                    let fileHandle = try FileHandle(forWritingTo: notesURL)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                } else {
                    try data.write(to: notesURL)
                }
            }
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    @objc func showSummary() {
        // Create custom window for date selection
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                             styleMask: [.titled, .closable],
                             backing: .buffered,
                             defer: false)
        window.title = "Notes Summary"
        window.center()
        
        // Create calendar date picker (graphical calendar)
        let datePicker = NSDatePicker(frame: NSRect(x: 20, y: 320, width: 300, height: 170))
        datePicker.datePickerStyle = .clockAndCalendar  // This shows the calendar view
        datePicker.datePickerElements = [.yearMonthDay]  // Only show date, not time
        datePicker.datePickerMode = .single
        datePicker.dateValue = Date()
        datePicker.maxDate = Date()
        
        // Create label for selected date
        let dateLabel = NSTextField(labelWithString: "Select a date from the calendar above")
        dateLabel.frame = NSRect(x: 340, y: 450, width: 240, height: 20)
        dateLabel.font = NSFont.systemFont(ofSize: 13)
        
        // Create text view for notes
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 50, width: 560, height: 250))
        let textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: 12)
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        // Create close button
        let closeButton = NSButton(frame: NSRect(x: 500, y: 10, width: 80, height: 30))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.target = window
        closeButton.action = #selector(NSWindow.close)
        
        // Function to load notes for selected date
        let loadNotes = {
            let notes = self.getNotesForDate(datePicker.dateValue)
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            
            dateLabel.stringValue = formatter.string(from: datePicker.dateValue)
            
            if notes.isEmpty {
                textView.string = "No notes recorded for this date"
            } else {
                let header = "📝 \(notes.count) notes recorded:\n\n"
                let summary = notes.map { "[\($0.time)] \($0.text)" }.joined(separator: "\n\n")
                textView.string = header + summary
            }
        }
        
        // Set up date picker action to auto-load when date changes
        datePicker.target = self
        datePicker.action = #selector(datePickerChanged(_:))
        
        // Store references for the action
        objc_setAssociatedObject(datePicker, "loadNotes", loadNotes, .OBJC_ASSOCIATION_COPY)
        
        // Initial load
        loadNotes()
        
        // Add subviews
        window.contentView?.addSubview(datePicker)
        window.contentView?.addSubview(dateLabel)
        window.contentView?.addSubview(scrollView)
        window.contentView?.addSubview(closeButton)
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func datePickerChanged(_ sender: NSDatePicker) {
        if let loadNotes = objc_getAssociatedObject(sender, "loadNotes") as? () -> Void {
            loadNotes()
        }
    }
    
    func getTodaysNotes() -> [(time: String, text: String)] {
        return getNotesForDate(Date())
    }
    
    func getNotesForDate(_ targetDate: Date) -> [(time: String, text: String)] {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let notesURL = homeURL.appendingPathComponent(".notes.txt")
        
        guard let content = try? String(contentsOf: notesURL, encoding: .utf8) else {
            return []
        }
        
        let formatter = ISO8601DateFormatter()
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: targetDate)
        
        var notes: [(time: String, text: String)] = []
        
        for line in content.components(separatedBy: .newlines) {
            if let separatorIndex = line.firstIndex(of: "|") {
                let timestampStr = String(line[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
                let noteText = String(line[line.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)
                
                if let date = formatter.date(from: timestampStr),
                   calendar.isDate(date, inSameDayAs: targetDay) {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "HH:mm"
                    notes.append((time: timeFormatter.string(from: date), text: noteText))
                }
            }
        }
        
        return notes
    }
    
    func getRecentNotes(limit: Int = 2) -> [(time: String, text: String)] {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let notesURL = homeURL.appendingPathComponent(".notes.txt")
        
        guard let content = try? String(contentsOf: notesURL, encoding: .utf8) else {
            return []
        }
        
        let formatter = ISO8601DateFormatter()
        var allNotes: [(date: Date, time: String, text: String)] = []
        
        for line in content.components(separatedBy: .newlines) {
            if let separatorIndex = line.firstIndex(of: "|") {
                let timestampStr = String(line[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
                let noteText = String(line[line.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)
                
                if let date = formatter.date(from: timestampStr), !noteText.isEmpty {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "MMM d, HH:mm"
                    allNotes.append((date: date, time: timeFormatter.string(from: date), text: noteText))
                }
            }
        }
        
        // Sort by date and return the most recent ones
        let recentNotes = allNotes.sorted { $0.date > $1.date }.prefix(limit)
        return recentNotes.map { (time: $0.time, text: $0.text) }
    }
    
    @objc func toggleEOD() {
        settings.isEOD.toggle()
        settings.save()
        
        let message = settings.isEOD ? 
            "No more notifications today" : 
            "You will receive hourly check-ins"
        showNotification(title: settings.isEOD ? "EOD Activated" : "Notifications Resumed", body: message)
    }
    
    @objc func showSettings() {
        let alert = NSAlert()
        alert.messageText = "Settings"
        alert.informativeText = "Configure work schedule and reminder frequency"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        // Main container
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 160))
        
        // Main stack view
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 16
        mainStack.alignment = .leading
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Create consistent label and popup widths for grid alignment
        let labelWidth: CGFloat = 100
        let popupWidth: CGFloat = 100
        
        // Start hour row
        let startRow = NSStackView()
        startRow.orientation = .horizontal
        startRow.spacing = 10
        startRow.alignment = .centerY
        
        let startLabel = NSTextField(labelWithString: "Start Hour:")
        startLabel.alignment = .right
        startLabel.translatesAutoresizingMaskIntoConstraints = false
        startLabel.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        
        let startHourPopup = NSPopUpButton()
        for hour in 0...23 {
            let displayTime = hour == 0 ? "12 AM" : 
                             hour < 12 ? "\(hour) AM" : 
                             hour == 12 ? "12 PM" : 
                             "\(hour - 12) PM"
            startHourPopup.addItem(withTitle: displayTime)
        }
        startHourPopup.selectItem(at: settings.workStartHour)
        startHourPopup.translatesAutoresizingMaskIntoConstraints = false
        startHourPopup.widthAnchor.constraint(equalToConstant: popupWidth).isActive = true
        
        startRow.addArrangedSubview(startLabel)
        startRow.addArrangedSubview(startHourPopup)
        
        // End hour row
        let endRow = NSStackView()
        endRow.orientation = .horizontal
        endRow.spacing = 10
        endRow.alignment = .centerY
        
        let endLabel = NSTextField(labelWithString: "End Hour:")
        endLabel.alignment = .right
        endLabel.translatesAutoresizingMaskIntoConstraints = false
        endLabel.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        
        let endHourPopup = NSPopUpButton()
        for hour in 0...23 {
            let displayTime = hour == 0 ? "12 AM" : 
                             hour < 12 ? "\(hour) AM" : 
                             hour == 12 ? "12 PM" : 
                             "\(hour - 12) PM"
            endHourPopup.addItem(withTitle: displayTime)
        }
        endHourPopup.selectItem(at: settings.workEndHour)
        endHourPopup.translatesAutoresizingMaskIntoConstraints = false
        endHourPopup.widthAnchor.constraint(equalToConstant: popupWidth).isActive = true
        
        endRow.addArrangedSubview(endLabel)
        endRow.addArrangedSubview(endHourPopup)
        
        // Frequency row
        let frequencyRow = NSStackView()
        frequencyRow.orientation = .horizontal
        frequencyRow.spacing = 10
        frequencyRow.alignment = .centerY
        
        let freqLabel = NSTextField(labelWithString: "Frequency:")
        freqLabel.alignment = .right
        freqLabel.translatesAutoresizingMaskIntoConstraints = false
        freqLabel.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        
        let frequencyPopup = NSPopUpButton()
        frequencyPopup.addItem(withTitle: "30 minutes")
        frequencyPopup.addItem(withTitle: "1 hour")
        frequencyPopup.addItem(withTitle: "2 hours")
        
        // Set current selection based on settings
        switch settings.frequencyMinutes {
        case 30:
            frequencyPopup.selectItem(at: 0)
        case 60:
            frequencyPopup.selectItem(at: 1)
        case 120:
            frequencyPopup.selectItem(at: 2)
        default:
            frequencyPopup.selectItem(at: 1) // Default to 1 hour
        }
        
        frequencyPopup.translatesAutoresizingMaskIntoConstraints = false
        frequencyPopup.widthAnchor.constraint(equalToConstant: popupWidth).isActive = true
        
        frequencyRow.addArrangedSubview(freqLabel)
        frequencyRow.addArrangedSubview(frequencyPopup)
        
        // Auto-start row
        let autoStartRow = NSStackView()
        autoStartRow.orientation = .horizontal
        autoStartRow.spacing = 10
        autoStartRow.alignment = .centerY
        
        let autoStartLabel = NSTextField(labelWithString: "Auto-start:")
        autoStartLabel.alignment = .right
        autoStartLabel.translatesAutoresizingMaskIntoConstraints = false
        autoStartLabel.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        
        let autoStartCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)
        autoStartCheckbox.state = settings.launchAtLogin ? .on : .off
        
        autoStartRow.addArrangedSubview(autoStartLabel)
        autoStartRow.addArrangedSubview(autoStartCheckbox)
        
        // Add all rows to main stack
        mainStack.addArrangedSubview(startRow)
        mainStack.addArrangedSubview(endRow)
        mainStack.addArrangedSubview(frequencyRow)
        mainStack.addArrangedSubview(autoStartRow)
        
        // Add main stack to container
        containerView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        alert.accessoryView = containerView
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let start = startHourPopup.indexOfSelectedItem
            let end = endHourPopup.indexOfSelectedItem
            
            settings.workStartHour = start
            settings.workEndHour = end
            
            // Get frequency from popup
            switch frequencyPopup.indexOfSelectedItem {
            case 0:
                settings.frequencyMinutes = 30
            case 1:
                settings.frequencyMinutes = 60
            case 2:
                settings.frequencyMinutes = 120
            default:
                settings.frequencyMinutes = 60
            }
            
            // Handle auto-start setting
            let newAutoStartState = autoStartCheckbox.state == .on
            if settings.launchAtLogin != newAutoStartState {
                settings.launchAtLogin = newAutoStartState
                updateLaunchAtLogin(enabled: newAutoStartState)
            }
            
            settings.save()
            rescheduleChecks()
            
            let startTime = start == 0 ? "12 AM" : 
                           start < 12 ? "\(start) AM" : 
                           start == 12 ? "12 PM" : 
                           "\(start - 12) PM"
            let endTime = end == 0 ? "12 AM" : 
                         end < 12 ? "\(end) AM" : 
                         end == 12 ? "12 PM" : 
                         "\(end - 12) PM"
                         
            showNotification(title: "Settings Saved", 
                           body: "Work hours: \(startTime) - \(endTime), Every \(settings.frequencyMinutes)min")
        }
    }
    
    func setupSleepWakeNotifications() {
        // Listen for sleep/wake events
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }
    
    @objc func systemWillSleep() {
        // Store the time when system goes to sleep
        lastCheckTime = Date()
    }
    
    @objc func systemDidWake() {
        // Check for missed hours when system wakes up
        checkForMissedHours()
        
        // Restart the timer
        timer?.invalidate()
        startHourlyTimer()
    }
    
    func checkForMissedHours() {
        guard let lastCheck = lastCheckTime else {
            // First run, just set current time
            lastCheckTime = Date()
            return
        }
        
        let now = Date()
        let hoursSinceLastCheck = Calendar.current.dateComponents([.hour], from: lastCheck, to: now).hour ?? 0
        
        // If more than 1 hour has passed, ask about missed hours
        if hoursSinceLastCheck > 1 {
            let calendar = Calendar.current
            
            // Check each missed hour to see if it was during work hours
            for i in 1..<hoursSinceLastCheck {
                if let missedHour = calendar.date(byAdding: .hour, value: i, to: lastCheck) {
                    // Check if this missed hour was during work hours
                    if isWorkHours(for: missedHour) && !settings.isEOD {
                        showMissedHourDialog(for: missedHour)
                    }
                }
            }
        }
        
        lastCheckTime = now
    }
    
    func showMissedHourDialog(for date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: date)
        
        let alert = NSAlert()
        alert.messageText = "Missed Check-in"
        alert.informativeText = "What were you working on around \(timeString)?\n(Your system was asleep or the app wasn't running)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Skip")
        
        // Create main container view
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 140))
        
        // Get recent notes for context (from before the missed time)
        let recentNotes = getRecentNotes(limit: 2)
        var yOffset: CGFloat = 140
        
        // Add recent notes section if available
        if !recentNotes.isEmpty {
            let recentLabel = NSTextField(labelWithString: "Recent activity (for context):")
            recentLabel.font = NSFont.boldSystemFont(ofSize: 11)
            recentLabel.textColor = NSColor.secondaryLabelColor
            recentLabel.frame = NSRect(x: 0, y: yOffset - 15, width: 400, height: 15)
            containerView.addSubview(recentLabel)
            yOffset -= 20
            
            for note in recentNotes {
                let noteText = "[\(note.time)] \(note.text)"
                let truncatedText = String(noteText.prefix(70)) + (noteText.count > 70 ? "..." : "")
                
                let noteLabel = NSTextField(labelWithString: truncatedText)
                noteLabel.font = NSFont.systemFont(ofSize: 10)
                noteLabel.textColor = NSColor.tertiaryLabelColor
                noteLabel.frame = NSRect(x: 10, y: yOffset - 15, width: 380, height: 15)
                noteLabel.lineBreakMode = .byTruncatingTail
                containerView.addSubview(noteLabel)
                yOffset -= 18
            }
            
            // Add separator line
            let separator = NSBox(frame: NSRect(x: 0, y: yOffset - 5, width: 400, height: 1))
            separator.boxType = .separator
            containerView.addSubview(separator)
            yOffset -= 10
        }
        
        let textField = NSTextView(frame: NSRect(x: 0, y: 0, width: 400, height: yOffset - 10))
        textField.isEditable = true
        textField.isSelectable = true
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.isAutomaticQuoteSubstitutionEnabled = false
        textField.isRichText = false
        textField.string = "System was asleep - "
        
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: yOffset - 10))
        scrollView.documentView = textField
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        containerView.addSubview(scrollView)
        alert.accessoryView = containerView
        
        // Focus on the text field and position cursor after the default text
        DispatchQueue.main.async {
            textField.becomeFirstResponder()
            textField.setSelectedRange(NSRange(location: textField.string.count, length: 0))
        }
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let text = textField.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                saveNoteWithCustomTime(text, time: date)
            }
        }
    }
    
    func saveNoteWithCustomTime(_ text: String, time: Date) {
        let timestamp = ISO8601DateFormatter().string(from: time)
        let noteEntry = "\(timestamp) | \(text)\n"
        
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let notesURL = homeURL.appendingPathComponent(".notes.txt")
        
        do {
            if let data = noteEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: notesURL.path) {
                    let fileHandle = try FileHandle(forWritingTo: notesURL)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                } else {
                    try data.write(to: notesURL)
                }
            }
        } catch {
            print("Error saving backdated note: \(error)")
        }
    }
    
    func startHourlyTimer() {
        let now = Date()
        let calendar = Calendar.current
        let frequencySeconds = Double(settings.frequencyMinutes * 60)
        
        // Calculate next check time based on work start time and frequency
        let todayWorkStart = calendar.date(bySettingHour: settings.workStartHour, minute: 0, second: 0, of: now) ?? now
        
        var nextCheckTime = todayWorkStart
        
        // If we're past today's work start, find the next interval
        if now > todayWorkStart {
            let timePassedSinceStart = now.timeIntervalSince(todayWorkStart)
            let intervalsPassed = Int(timePassedSinceStart / frequencySeconds)
            nextCheckTime = todayWorkStart.addingTimeInterval(Double(intervalsPassed + 1) * frequencySeconds)
        }
        
        // If the next check time is outside work hours, move to next day
        if !isWorkHours(for: nextCheckTime) {
            // Move to tomorrow's work start
            if let tomorrowWorkStart = calendar.date(byAdding: .day, value: 1, to: todayWorkStart) {
                nextCheckTime = tomorrowWorkStart
            }
        }
        
        let timeInterval = max(1, nextCheckTime.timeIntervalSince(now))
        
        // Schedule first check
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            self.regularCheck()
            // Then repeat at the frequency interval
            self.timer = Timer.scheduledTimer(withTimeInterval: frequencySeconds, repeats: true) { _ in
                self.regularCheck()
            }
        }
        
        // Update last check time
        lastCheckTime = now
    }
    
    func regularCheck() {
        if isWorkHours() && !settings.isEOD {
            showNoteDialog()
        }
        lastCheckTime = Date()
    }
    
    func rescheduleChecks() {
        timer?.invalidate()
        startHourlyTimer()
    }
    
    func syncLaunchAtLoginState() {
        if #available(macOS 13.0, *) {
            // Check current status and sync with settings
            let status = SMAppService.mainApp.status
            let isEnabled = (status == .enabled)
            if settings.launchAtLogin != isEnabled {
                settings.launchAtLogin = isEnabled
                settings.save()
            }
        }
    }
    
    func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            // Use the modern Service Management API for macOS 13+
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
                // Show error to user
                let alert = NSAlert()
                alert.messageText = "Auto-start Error"
                alert.informativeText = "Failed to update auto-start setting: \(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.runModal()
            }
        } else {
            // For older macOS versions, inform user to add manually
            let alert = NSAlert()
            alert.messageText = "Auto-start Not Available"
            alert.informativeText = "Auto-start requires macOS 13.0 or later. Please add HourlyNotes to Login Items manually in System Preferences."
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    func hourlyCheck() {
        if isWorkHours() && !settings.isEOD {
            showNoteDialog()
        }
    }
    
    func isWorkHours() -> Bool {
        return isWorkHours(for: Date())
    }
    
    func isWorkHours(for date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        if settings.workStartHour <= settings.workEndHour {
            return hour >= settings.workStartHour && hour < settings.workEndHour
        } else {
            // Handle overnight hours
            return hour >= settings.workStartHour || hour < settings.workEndHour
        }
    }
    
    func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permissions granted")
            }
        }
    }
    
    func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, 
                                           content: content, 
                                           trigger: nil)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Settings Manager
class UserSettings {
    var workStartHour: Int = 9
    var workEndHour: Int = 17
    var frequencyMinutes: Int = 60
    var isEOD: Bool = false
    var launchAtLogin: Bool = false
    private var eodDate: Date?
    
    private var settingsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".hourly_notes_settings.json")
    }
    
    func load() {
        guard let data = try? Data(contentsOf: settingsURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        workStartHour = json["workStartHour"] as? Int ?? 9
        workEndHour = json["workEndHour"] as? Int ?? 17
        frequencyMinutes = json["frequencyMinutes"] as? Int ?? 60
        launchAtLogin = json["launchAtLogin"] as? Bool ?? false
        
        // Check if EOD is for today
        if let eodDateStr = json["eodDate"] as? String,
           let date = ISO8601DateFormatter().date(from: eodDateStr),
           Calendar.current.isDateInToday(date) {
            isEOD = true
            eodDate = date
        } else {
            isEOD = false
            eodDate = nil
        }
    }
    
    func save() {
        var json: [String: Any] = [
            "workStartHour": workStartHour,
            "workEndHour": workEndHour,
            "frequencyMinutes": frequencyMinutes,
            "launchAtLogin": launchAtLogin
        ]
        
        if isEOD {
            eodDate = Date()
            json["eodDate"] = ISO8601DateFormatter().string(from: eodDate!)
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: json) {
            try? data.write(to: settingsURL)
        }
    }
}

// MARK: - Main Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hide from dock
app.run()