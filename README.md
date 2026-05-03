# AuraWriter

> A lighweight macOS menu bar application that enhances your writing skill with AI-powered backend.

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-green.svg)](https://developer.apple.com/xcode/swiftui/)

Select any text in any application, trigger AuraWriter with a keyboard shortcut, and instantly transform it using customizable AI agents.

## Features

- **Global Keyboard Shortcut**: Trigger text rewriting from any macOS application with a customizable hotkey (default: ⌘⇧A)
- **Multiple AI Agents**: Configure multiple agents with different prompts and backends
- **Flexible Backend Support**: Works with OpenAI API and any OpenAI-compatible API endpoint
- **Smart Agent Selection**: Set default agents per application for faster workflow
- **Revert Capability**: Undo recent changes within 5 minutes
- **Menu Bar Integration**: Lightweight menu bar app that stays out of your way
- **Accessibility-Powered**: Uses macOS Accessibility APIs to read and replace text seamlessly

## Requirements

- **macOS 14.0 (Sonoma) or later**
- Accessibility permissions (required for text selection and replacement)
- OpenAI API key or compatible API endpoint

## Installation

### Download

1. Download the latest release from the [Releases](https://github.com/yourusername/AuraWriter/releases) page
2. Move `AuraWriter.app` to your Applications folder
3. Launch AuraWriter
4. Grant Accessibility permissions when prompted:
   - **System Settings → Privacy & Security → Accessibility → Enable AuraWriter**

### Build from Source

See the [Development](#development) section below.

## Setup

### Configure API Keys

1. Click the AuraWriter icon in the menu bar
2. Select "Manage Agents"
3. Edit each agent to add your API key:
   - For OpenAI: Get your API key from https://platform.openai.com/api-keys
   - For other providers: Use your provider's API key and endpoint URL

### Customize Keyboard Shortcut

1. Click the AuraWriter menu bar icon
2. Select "Change Keyboard Shortcut"
3. Press your desired key combination
4. The shortcut is saved automatically

### Add Custom Agents

1. Open "Manage Agents" from the menu bar
2. Click "Add Agent"
3. Configure:
   - **Name**: Display name for the agent
   - **Backend URL**: API endpoint (e.g., `https://api.openai.com/v1/chat/completions`)
   - **Model Name**: Model identifier (e.g., `gpt-4`, `gpt-3.5-turbo`)
   - **Default Prompt**: Instructions for how to transform the text
   - **API Key**: Your authentication key

### Set Per-App Defaults

1. Switch to the application where you want to set a default agent
2. Open AuraWriter's menu bar menu
3. Select your preferred agent from the "Set as default for [App Name]" section

## Usage

1. Select text in any application
2. Press your keyboard shortcut (default: ⌘⇧A)
3. Choose an agent from the popup (or use the pre-selected default)
4. Click "Rewrite" or press Enter
5. The selected text is replaced with the AI-generated version

### Temporarily Disable Hotkey

If the global shortcut conflicts with another app:

1. Click the AuraWriter menu bar icon
2. Select "Temporarily Disable Hotkey"
3. Re-enable it later from the same menu

## Architecture

AuraWriter is built with Swift and SwiftUI, using modern macOS APIs:

- **AppDelegate.swift**: Core application logic and service coordination
- **Services**:
  - `AgentService`: Manages agent configurations and persistence
  - `BackendService`: Handles API communication with configurable backends
  - `AccessibilityService`: Interfaces with macOS Accessibility APIs
  - `KeyboardShortcutService`: Registers and manages global hotkeys
  - `PreferencesService`: Stores user preferences and per-app defaults
- **Models**:
  - `Agent`: Represents an AI agent configuration
  - `Preferences`: User settings and keyboard shortcuts
  - `RevertState`: Tracks changes for undo functionality
- **Views**:
  - `MenuBarView`: Menu bar dropdown interface
  - `PopupContentView`: Text rewriting dialog
  - `AgentListView`: Agent management interface
  - `AgentFormView`: Agent creation/editing form

## API Compatibility

AuraWriter works with any API that follows the OpenAI chat completions format:

```json
POST /v1/chat/completions
{
  "model": "model-name",
  "messages": [
    {
      "role": "user",
      "content": "prompt + selected text"
    }
  ]
}
```

Compatible services include:
- OpenAI API
- Azure OpenAI
- Anthropic Claude (via proxy)
- Local LLMs (Ollama, LM Studio, etc.)
- Any OpenAI-compatible endpoint

## Privacy & Security

- **Secure Storage**: All API keys are stored securely in the macOS Keychain
- **No Telemetry**: No analytics or usage data is collected
- **Local First**: The app runs entirely locally except for API calls to your configured endpoints
- **You Control the Data**: Text is only sent to the backend URLs you configure
- **Open Source**: Full source code is available for audit

## Troubleshooting

### Keyboard shortcut not working

1. Check that Accessibility permissions are granted
2. Verify the shortcut isn't conflicting with system or other app shortcuts
3. Try temporarily disabling and re-enabling the hotkey from the menu

### "Failed to replace text" error

1. Ensure the target application is still focused
2. Check that the text field is still editable
3. Some applications may restrict programmatic text replacement

### API errors

1. Verify your API key is correct
2. Check that the backend URL is valid
3. Ensure the model name is supported by your backend
4. Check your API quota/billing status

### Agent configuration not saving

1. Check file permissions in `~/Library/Application Support/AuraWriter/`
2. Restart the application
3. Try removing and re-adding the agent

## Development

### Building from Source

**Requirements:**
- Xcode 16.0 or later
- macOS 14.0 SDK or later
- Swift 5.0+

**Steps:**

```bash
# Clone the repository
git clone https://github.com/yourusername/AuraWriter.git
cd AuraWriter

# Open in Xcode
open AuraWriter.xcodeproj

# Build and run (⌘R)
```

### Project Structure

```
AuraWriter/
├── AuraWriter/
│   ├── AuraWriterApp.swift       # App entry point
│   ├── AppDelegate.swift         # Main application logic
│   ├── Models/                   # Data models
│   │   ├── Agent.swift           # AI agent configuration
│   │   ├── Preferences.swift    # User preferences
│   │   └── RevertState.swift    # Undo state tracking
│   ├── Services/                 # Business logic
│   │   ├── AccessibilityService.swift    # macOS Accessibility APIs
│   │   ├── AgentService.swift            # Agent management
│   │   ├── BackendService.swift          # API communication
│   │   ├── KeyboardShortcutService.swift # Global hotkey handling
│   │   └── PreferencesService.swift      # Settings persistence
│   └── Views/                    # SwiftUI views
│       ├── MenuBarView.swift
│       ├── PopupContentView.swift
│       ├── AgentListView.swift
│       └── AgentFormView.swift
└── AuraWriter.xcodeproj/         # Xcode project
```

### Technical Details

**Built with:**
- Swift 5.0 with modern concurrency (async/await)
- SwiftUI for the user interface
- Combine for reactive state management
- macOS Accessibility APIs for text manipulation
- Carbon Events for global keyboard shortcuts

**Key APIs:**
- `AXUIElement` - Reading and replacing text in any app
- `EventHotKey` - Global keyboard shortcut registration
- `URLSession` - Async HTTP requests to AI backends
- `Keychain Services` - Secure API key storage

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Credits

Created by [Trong Nguyen](https://github.com/lidroider)

