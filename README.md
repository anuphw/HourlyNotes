# HourlyNotes 📝

A native macOS menu bar app that helps you track your daily activities with gentle hourly check-ins. Built entirely in Swift with zero external dependencies.

![HourlyNotes Demo](https://raw.githubusercontent.com/anuphw/HourlyNotes/main/demo.gif)

## 💭 The Story Behind HourlyNotes

As a developer, I often find myself in deep focus mode, working for hours on end. While this flow state is great for productivity, I realized I was losing track of all the small but meaningful progress I made throughout the day. 

By the time evening came around, when someone asked "What did you accomplish today?" or when I needed to write my daily standup notes, I'd struggle to remember. Did I fix that authentication bug before or after lunch? When did I finish the API refactoring? What was that brilliant insight I had about the database optimization?

All these small victories, incremental improvements, and "aha!" moments were getting lost in the continuous stream of work. I tried various productivity apps, but they were either too complex, required too much setup, or felt intrusive to my workflow.

That's when I realized I needed something simple: just a gentle tap on the shoulder every hour asking, "Hey, what did you just accomplish?" Nothing fancy, nothing overwhelming - just a moment to capture the small wins and progress that make up our days.

HourlyNotes was born from this need. It's the app I wish I had during those long coding sessions - a quiet companion that helps me remember not just what I did, but also appreciate how much I actually accomplish in a day.

## ✨ Features

- **📱 Native macOS App**: Built with Swift/Cocoa - no Python or external dependencies
- **⏰ Smart Scheduling**: Automatic hourly prompts during your configured work hours
- **📅 Calendar View**: Browse your activity history with an intuitive calendar interface
- **💾 Simple Storage**: All notes saved to `~/.notes.txt` with timestamps
- **🔕 EOD Mode**: Disable notifications when you're done for the day
- **⚙️ Configurable**: Set your own work hours (default: 9 AM - 6 PM)
- **🎯 Menu Bar Integration**: Lives quietly in your menu bar until needed
- **📊 Activity Summaries**: View your daily accomplishments at a glance

## 🚀 Quick Start

### Download & Install

1. **Download**: Get the latest [HourlyNotes.dmg](https://github.com/anuphw/HourlyNotes/releases/latest)
2. **Install**: Open the DMG and drag HourlyNotes.app to Applications
3. **Launch**: Open the app - you'll see a 📝 icon in your menu bar
4. **Permissions**: Grant notification permissions when prompted

That's it! The app will automatically prompt you every hour during work hours.

### Building from Source

```bash
git clone https://github.com/anuphw/HourlyNotes.git
cd HourlyNotes
chmod +x build_native_app.sh
./build_native_app.sh
open HourlyNotes.app
```

## 📖 How to Use

### Menu Bar Options

Click the 📝 icon in your menu bar to access:

- **Add Note Now** - Manually record what you're working on
- **EOD (End of Day)** - Stop notifications for the rest of today
- **Today's Summary** - View your activities with calendar navigation
- **Settings** - Configure your work hours
- **Quit** - Exit the application

### Calendar Navigation

The "Today's Summary" feature includes a visual calendar where you can:
- Click any date to view notes from that day
- Navigate between months using arrow buttons
- See your complete activity history
- Search through past accomplishments

### Data Storage

All your notes are stored locally in `~/.notes.txt` with this format:
```
2024-08-30T14:00:00 | Completed the user authentication feature
2024-08-30T15:00:00 | Team standup and sprint planning
2024-08-30T16:00:00 | Fixed critical bug in payment processing
```

## ⚡ Why HourlyNotes?

### The Problem
- Hard to remember what you accomplished during the day
- Difficult to track time spent on different tasks
- Writing detailed daily reports feels overwhelming
- Productivity apps are too complex or invasive

### The Solution
- **Gentle Reminders**: Simple hourly check-ins that don't interrupt flow
- **Minimal Interface**: Just a text box - write as much or as little as you want
- **Local Storage**: Your data stays on your machine
- **Zero Dependencies**: Native app that starts instantly
- **Historical View**: Easy browsing of past activities

## 🛠 Technical Details

- **Language**: 100% Swift
- **Frameworks**: Cocoa, UserNotifications
- **macOS**: Requires macOS 10.15+
- **Architecture**: ARM64 & x86_64 universal binary
- **Size**: < 1MB app bundle
- **Dependencies**: None - completely self-contained

## 📁 File Structure

```
HourlyNotes/
├── HourlyNotes.swift          # Main application code
├── build_native_app.sh        # Build script
├── icon.icns                  # App icon
├── com.hourly-notes.plist     # Launch agent config
└── README.md                  # This file
```

## 🔧 Configuration

### Work Hours
Default: 9:00 AM - 6:00 PM  
Configure through: Menu Bar → Settings

### Launch at Startup
To auto-start the app when you log in:

```bash
cp com.hourly-notes.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.hourly-notes.plist
```

### Data Location
- Notes: `~/.notes.txt`  
- Settings: `~/.hourly_notes_settings.json`

## 🎨 Customization

### Changing Work Hours
1. Click the menu bar icon
2. Select "Settings"
3. Enter new start/end times (24-hour format)
4. Click "Save"

### EOD (End of Day)
When you're done working for the day:
1. Click "EOD (End of Day)" from the menu
2. No more notifications until tomorrow
3. Click again to resume notifications

## 📊 Use Cases

- **Developers**: Track features completed, bugs fixed, meetings attended
- **Consultants**: Log billable hours and client work
- **Students**: Monitor study sessions and project progress
- **Remote Workers**: Stay accountable and track productivity
- **Anyone**: Build awareness of how time is spent

## 🤝 Contributing

We welcome contributions! Here's how to help:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin amazing-feature`
5. **Open** a Pull Request

### Development Setup

```bash
# Clone the repo
git clone https://github.com/anuphw/HourlyNotes.git
cd HourlyNotes

# Build and run
./build_native_app.sh
open HourlyNotes.app

# Or compile directly
swiftc -o HourlyNotes HourlyNotes.swift -framework Cocoa -framework UserNotifications
```

## 📋 Roadmap

- [ ] **Export Features**: CSV/JSON export of activity data
- [ ] **Themes**: Light/dark mode customization
- [ ] **Categories**: Tag activities by project or type
- [ ] **Statistics**: Weekly/monthly activity insights
- [ ] **Reminders**: Custom reminder intervals
- [ ] **Integration**: Slack/Teams status updates

## ❓ FAQ

**Q: Does this app send my data anywhere?**  
A: No. All data is stored locally on your machine.

**Q: Can I use this for time tracking?**  
A: Yes! Each note includes a timestamp for easy time analysis.

**Q: What if I miss an hourly prompt?**  
A: No worries - you can always add notes manually via "Add Note Now".

**Q: Can I change the notification sound?**  
A: Currently uses system default. Customization planned for future versions.

**Q: Does it work with multiple monitors?**  
A: Yes! Dialogs appear on your active screen.

## 🐛 Issues & Support

Found a bug or have a feature request?

1. Check existing [issues](https://github.com/anuphw/HourlyNotes/issues)
2. Create a new issue with:
   - macOS version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if relevant

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- Built with love for the productivity community
- Inspired by the Pomodoro Technique and time tracking methodologies
- Special thanks to early testers and contributors

---

**Made with ❤️ for macOS users who want to be more mindful of their daily activities.**

[Download Latest Release](https://github.com/anuphw/HourlyNotes/releases/latest) • [Report Issue](https://github.com/anuphw/HourlyNotes/issues) • [Contribute](https://github.com/anuphw/HourlyNotes/pulls)
