#!/usr/bin/swift
//
// HourlyNotes.swift
// Native macOS menu bar app for hourly activity tracking
// No external dependencies - pure Swift/Cocoa
//

import Cocoa
import UserNotifications
import Foundation

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
        
        let textField = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        textField.isEditable = true
        textField.isSelectable = true
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.isAutomaticQuoteSubstitutionEnabled = false
        textField.isRichText = false
        
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 100))
        scrollView.documentView = textField
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        alert.accessoryView = scrollView
        
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
        alert.informativeText = "Configure work hours (24-hour format)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        
        let stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 200, height: 60))
        stackView.orientation = .vertical
        stackView.spacing = 10
        
        // Start time
        let startStack = NSStackView()
        startStack.orientation = .horizontal
        startStack.spacing = 10
        
        let startLabel = NSTextField(labelWithString: "Start Hour:")
        startLabel.frame.size.width = 80
        let startField = NSTextField(string: "\(settings.workStartHour)")
        startField.frame.size.width = 50
        
        startStack.addArrangedSubview(startLabel)
        startStack.addArrangedSubview(startField)
        
        // End time
        let endStack = NSStackView()
        endStack.orientation = .horizontal
        endStack.spacing = 10
        
        let endLabel = NSTextField(labelWithString: "End Hour:")
        endLabel.frame.size.width = 80
        let endField = NSTextField(string: "\(settings.workEndHour)")
        endField.frame.size.width = 50
        
        endStack.addArrangedSubview(endLabel)
        endStack.addArrangedSubview(endField)
        
        stackView.addArrangedSubview(startStack)
        stackView.addArrangedSubview(endStack)
        
        alert.accessoryView = stackView
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let start = Int(startField.stringValue),
               let end = Int(endField.stringValue),
               (0...23).contains(start) && (0...23).contains(end) {
                settings.workStartHour = start
                settings.workEndHour = end
                settings.save()
                showNotification(title: "Settings Saved", 
                               body: "Work hours: \(start):00 - \(end):00")
            }
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
        
        let textField = NSTextView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
        textField.isEditable = true
        textField.isSelectable = true
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.isAutomaticQuoteSubstitutionEnabled = false
        textField.isRichText = false
        textField.string = "System was asleep - "
        
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
        scrollView.documentView = textField
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        alert.accessoryView = scrollView
        
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
        // Calculate next hour
        let now = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.hour! += 1
        components.minute = 0
        components.second = 0
        
        if let nextHour = calendar.date(from: components) {
            let timeInterval = nextHour.timeIntervalSince(now)
            
            // Schedule first check
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
                self.hourlyCheck()
                // Then repeat every hour
                self.timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
                    self.hourlyCheck()
                }
            }
        }
        
        // Update last check time
        lastCheckTime = now
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
    var workEndHour: Int = 18
    var isEOD: Bool = false
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
        workEndHour = json["workEndHour"] as? Int ?? 18
        
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
            "workEndHour": workEndHour
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