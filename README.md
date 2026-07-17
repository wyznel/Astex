# Astex

Astex is a native macOS app designed to provide a modern chat interface for interacting primarily with local llms built entirely using Swift.
                                                                                                    
## Features

- **Local AI Execution:** Interacts directly with Ollama to run models locally, ensuring complete privacy and offline capabilities.
- **Persistent Chat History:** Automatically saves your conversations and message history using SwiftData.
- **Smart Chat Titles:** Automatically generates contextual titles for your chats based on the ongoing conversation.
- **Chat History:** Saves all chats locally for future access.
- **Completely Offline:** Astex doesn't require an internet connection (as long as you already have a model installed)
- **Model Management:** Able to load, delete, and pull models via the app. 
## Requirements

- macOS 26+
- [Ollama](https://ollama.ai) already installed.

## Installation and Setup

1. At the moment [Ollama](https://ollama.com/) is required, ensure it is installed.
2. Download latest release from [releases](https://github.com/wyznel/Astex/releases)
3. On first open you will need to open privacy settings and allow Astex to open, Gatekeeper flags Astex as harmful.
4. MacOS then tags Astex with a quarantine attribute preventing it from opening, run `xattr -cr /Applications/Astex.app` to remove the flag.
5. You will only need to do this once.



### Roadmap

See [roadmap.md](https://github.com/wyznel/Astex/blob/main/ROADMAP.md)
