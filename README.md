# HourlyNotes 📝

A native macOS menu bar app that helps you track your daily activities with gentle hourly check-ins. Built entirely in Swift with zero external dependencies.

![HourlyNotes Demo](https://raw.githubusercontent.com/anuphw/HourlyNotes/main/demo.gif)

## 💭 The Story Behind HourlyNotes

As a GenAI researcher working in the generative image field, I have a confession: I'm terrible at logging my work. I'm chronically lazy about documentation and keep procrastinating on writing down what I've done. "I'll remember this experiment," I tell myself. "I'll log it later when I have more results."

But "later" never comes. Days turn into weeks, and suddenly I'm staring at a blank weekly report with no memory of what I actually accomplished. Worse, as a researcher, I'm constantly running experiments that fail - and I just move on to the next idea without documenting what went wrong. Those failed experiments? They disappear into the void, along with valuable insights about what doesn't work.

The breaking point came during my weekly progress meeting when my advisor asked about a specific experiment I'd run three days earlier. I remembered running it, I remembered it failing, but I couldn't recall the exact setup, the parameters I'd used, or why it failed. All that work and learning - gone.

I realized the problem wasn't that I couldn't remember things - it was that I was trying to remember too much at once. By the end of the week, there was simply too much to recall and log properly. 

That's when I had an idea: What if I could break down the logging into tiny, manageable pieces? Just a gentle hourly reminder asking, "Hey, what did you just work on?" - successful experiments, failed runs, insights, dead ends, everything. No pressure to write a comprehensive report, just capture the moment while it's fresh.

HourlyNotes was born from this laziness-driven problem. It's my solution for procrastinating researchers who need to build up their weekly reports from small, real-time breadcrumbs. Now when Friday comes and I need to write that progress log, I have everything I need - including all those "failed" experiments that actually taught me something valuable.

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

### ⭐ Recommended: Build from Source

For the best experience and to avoid macOS Gatekeeper issues, we recommend compiling the app yourself:

```bash
git clone https://github.com/anuphw/HourlyNotes.git
cd HourlyNotes
chmod +x build_native_app.sh
./build_native_app.sh
open HourlyNotes.app
```

**Why build from source?**
- No macOS "damaged app" warnings
- Always get the latest code
- Full control over the build process
- Takes less than 30 seconds to compile

### Alternative: Download Pre-built App

⚠️ **Note**: Pre-built releases require bypassing macOS Gatekeeper since the app is not code-signed.

1. **Download**: Get the latest [HourlyNotes.dmg](https://github.com/anuphw/HourlyNotes/releases/latest)
2. **Install**: Open the DMG and drag HourlyNotes.app to Applications
3. **Launch**: **Right-click** the app and select "Open" (don't double-click)
4. **Confirm**: Click "Open" when macOS asks for confirmation
5. **Permissions**: Grant notification permissions when prompted

**Alternative bypass method:**
```bash
# Remove quarantine flag after installing to Applications
sudo xattr -rd com.apple.quarantine /Applications/HourlyNotes.app
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
2024-08-30T14:00:00 | Tried new attention mechanism - training diverged after 50 epochs, probably too high lr
2024-08-30T15:00:00 | Team meeting - advisor wants CVPR draft by next Friday, need to prioritize results
2024-08-30T16:00:00 | Fixed GAN discriminator! Issue was batch norm placement, loss stable now
2024-08-30T17:00:00 | Failed experiment: StyleGAN with CLIP loss - mode collapse after 20k steps, skip this approach
```

## ⚡ Why HourlyNotes?

### The Problem
- **Procrastination**: Always planning to "log it later" but never doing it
- **Information Overload**: Too much to remember by the end of the week
- **Lost Failed Experiments**: Moving on without documenting what went wrong
- **Weekly Report Anxiety**: Staring at blank reports with no memory of progress
- **Missed Learning Opportunities**: Valuable insights from failures get forgotten

### The Solution
- **Bite-Sized Logging**: Break down documentation into tiny, manageable pieces
- **Real-Time Capture**: Log things while they're fresh in your memory
- **No Judgment**: Capture successes AND failures equally
- **Weekly Report Builder**: Automatically have all the breadcrumbs for comprehensive reports
- **Failure Documentation**: Never lose insights from experiments that didn't work
- **Procrastination-Friendly**: Designed for people who hate logging but need to do it

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

- **AI/ML Researchers**: Track experiments, model improvements, breakthrough insights
- **Developers**: Log features completed, bugs fixed, code reviews
- **PhD Students**: Monitor research progress, paper writing, experimental results
- **Data Scientists**: Record model iterations, analysis discoveries, hypothesis testing
- **Consultants**: Log billable hours and client deliverables
- **Remote Workers**: Stay accountable and track daily accomplishments
- **Anyone**: Build awareness of incremental progress and daily wins

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
