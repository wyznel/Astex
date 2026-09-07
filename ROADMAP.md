# Astex road map

## 01 Foundation
- [x] README created
- [x] Chat saving and loading implemented
- [x] Automatic title generation
- [x] Migrate to use NavigationLink instead of custom sidebar
- [x] Implement compatibility with thinking models
- [x] Add autoupdater using Sparkle
- [x] Fix quarantine & Gatekeeper flagging

## 02 Model management
- [x] Model management tab
- [x] Show available models from all providers
- [x] Delete models
- [x] Unload models from memory
- [x] Pull models from Ollama

## 03 Chat experience
- [x] Update chat interface
- [x] Allow uploads of files
  - [x] Drag and drop files
- [x] Fix chat scroll resetting to top when sending a chat

## 04 Onboarding
- [x] Implemented Onboarding Menu

## 05 Appearance Settings v0.1
- [x] Light, Dark, System Appearance selection.
- [x] New themes
  - [x] Nord - Locked to dark
  - [x] Arctic
  - [x] Sage

## 06 In Progress
- [ ] Improved model download menu.
- [ ] More Tools
    - [ ] File management
        - [ ] read_file
        - [ ] list_directory
        - [ ] search_files (Spotlight-style via NSMetadataQuery)
    - [ ] Web search (keyless endpoint, e.g. DuckDuckGo)
    - [ ] Run Command (gated behind confirmation prompt and checked for destructive command)
    - [ ] Interacting with macOS natively
        - [ ] open_file / open_app (NSWorkspace)
        - [ ] get_calendar / get_reminders (EventKit, needs permission prompt)
        - [ ] set_reminder / notify_me (reuse NotificationManager)
    - [ ] get_weather (via keyless API, e.g. Open-Meteo)
    - [ ] fetch_url (be aware of prompt-injection risk from web content)
- [ ] Add ability to connect external MCPs
