# Aider.nvim

An AI-assisted coding plugin for Neovim, integrating the Aider CLI tool.

## TODO

- [ ] save current state (model, file list presistant)
- [ ] add current as readonly
- [x] add file from snacks file list
- [x] auto start (with deffer) aider if necessary when send to aider.
- [ ] tree-sitter on response
- [x] aider run in background when windows is close.
- [x] send code should include path and line info
- [x] :AiderNo
- [x] :AiderYes
- [x] defer reload modify file
- [x] scroll left when chunk changes came in
- [x] only enable log when .aider.xxxx exists
- [x] scroll to bottom when terminal on focus
- [x] show diagnostic in dialog before fix
- [ ] aider command in dialog
- [ ] forward aider confirmation to neovim ui
- [ ] show diff
- [ ] watching only aider is enabled or setup
- [x] sync buffers list to watch handler (active only)
- [x] send current file
- [x] watching file change
- [x] dialog for prompt
- [x] fix diagnostic

## System Architecture

### Terminal Processing Flow

```mermaid
sequenceDiagram
    participant Terminal as Terminal Buffer
    participant Events as Terminal Events
    participant State as State Manager
    participant Patterns as Pattern Handlers
    participant EventEmitter as Event System

    Terminal->>Events: Buffer Content Change
    Events->>Events: clean_terminal_line()

    rect rgb(200, 200, 255)
        Note over Events: Process Each Line
        Events->>Events: Parse Non-Empty Lines
        Events->>State: Add to History
        Events->>EventEmitter: emit("lines_changed")

        Note over Events,Patterns: Pattern Matching Process
        Events->>Events: Sort Handlers by Priority
        loop Each Handler
            Events->>Patterns: Try Match Pattern
            alt Match Found
                Patterns->>Patterns: validate()
                Patterns->>Patterns: preprocess()
                Patterns->>State: Update State
                Patterns->>Patterns: postprocess()
                Patterns->>EventEmitter: emit("pattern_matched")
            end
        end
    end

    Note over State: State Updates
    State-->>Terminal: Mode Change Callbacks
    EventEmitter-->>Terminal: Event Notifications
```
