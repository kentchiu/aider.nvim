# Aider.nvim

An AI-assisted coding plugin for Neovim that seamlessly sends information from your Neovim editor to tmux, enabling efficient workflow integration between your code and terminal sessions. Perfect for developers who use both tools together.

## TODO

- [ ] image selector
- [x] setup debug log and disable by default.
- [x] ~~save current state (model, file list presistant)~~ => use lua config
- [x] add current as readonly
- [x] add file from snacks file list
- [x] auto start (with deffer) aider if necessary when send to aider.
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
- [x] ~~show diff~~
- [x] watching only aider is enabled or setup
- [x] sync buffers list to watch handler (active only)
- [x] send current file
- [x] watching file change
- [x] dialog for prompt
- [x] fix diagnostic
