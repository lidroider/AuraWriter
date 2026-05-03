# AuraWriter

A macOS menu bar application that enhances your writing with AI-powered text rewriting. Select any text in any application, trigger AuraWriter with a keyboard shortcut, and instantly transform it using customizable AI agents.

## Features

- **Global Keyboard Shortcut**: Trigger text rewriting from any macOS application with a customizable hotkey (default: ⌘⇧A)
- **Multiple AI Agents**: Configure multiple agents with different prompts and backends
- **Flexible Backend Support**: Works with OpenAI API and any OpenAI-compatible API endpoint
- **Smart Agent Selection**: Set default agents per application for faster workflow
- **Revert Capability**: Undo recent changes within 5 minutes
- **Menu Bar Integration**: Lightweight menu bar app that stays out of your way
- **Accessibility-Powered**: Uses macOS Accessibility APIs to read and replace text seamlessly

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permissions (required for text selection and replacement)
- OpenAI API key or compatible API endpoint

## Installation

1. Download the latest release from the releases page
2. Move AuraWriter.app to your Applications folder
3. Launch AuraWriter
4. Grant Accessibility permissions when prompted:
   - System Settings → Privacy & Security → Accessibility → Enable AuraWriter

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

### Reverting Changes

If you need to undo a rewrite:

1. Click the AuraWriter menu bar icon
2. Select "Revert Last Change"
3. The original text is restored (available for 5 minutes after the change)

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

- All API keys are stored securely in the macOS Keychain
- Text is only sent to the backend URLs you configure
- No telemetry or analytics are collected
- The app runs entirely locally except for API calls

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
│   ├── Services/                 # Business logic
│   └── Views/                    # SwiftUI views
├── AuraWriterTests/              # Unit tests
└── AuraWriter.xcodeproj/         # Xcode project
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

[Add your license here]

## Credits

Created by Trong Nguyen (lidroider@gmail.com)

## Changelog

### Version 1.0.0 (2026-05-01)

- Initial release
- Multiple agent support
- Customizable keyboard shortcuts
- Per-app default agents
- Revert functionality
- OpenAI-compatible API support
