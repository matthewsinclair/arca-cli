---
verblock: "25 March 2025:v0.4.2: Claude - Fixed command alphabetical sorting implementation"
---
# Work In Progress

## TODO


## Notes

The Arca.Cli project is focused on providing a robust command-line interface framework for Elixir applications. Recent work has focused on improving the organization of commands using dot notation, enhancing the REPL experience, and improving documentation. The migration to the STP framework will help better organize project documentation and development process.

The new help subsystem work (ST004) will address fundamental issues with the current implementation, providing a more consistent and reliable approach to displaying help in both CLI and REPL modes. Rather than using help tuples, the revised approach uses a centralized help module with pre-execution checks, which provides a cleaner and more maintainable solution.

## Context for LLM

This document captures the current state of development on the project. When beginning work with an LLM assistant, start by sharing this document to provide context about what's currently being worked on.

### How to use this document

1. Update the "Current Focus" section with what you're currently working on
2. List active steel threads with their IDs and brief descriptions
3. Keep track of upcoming work items
4. Add any relevant notes that might be helpful for yourself or the LLM

When starting a new steel thread, describe it here first, then ask the LLM to create the appropriate steel thread document using the STP commands.