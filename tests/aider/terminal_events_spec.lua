local patterns = require("aider.patterns")
local terminal_events = require("aider.terminal_events")

describe("terminal_events PATTERNS", function()
  before_each(function()
    terminal_events.reset_state()
  end)

  describe("ReadonlyHandler", function()
    local handler = patterns.ReadonlyHandler:new()

    it("should parse single readonly file path", function()
      local line = "Readonly: path/to/file.txt"
      local matches = { line:match(handler.pattern) }
      local state = {}
      handler:handle(matches, state)
      assert.same({ "path/to/file.txt" }, state.readonly_files)
    end)

    it("should parse multiple comma-separated paths", function()
      local line = "Readonly: file1.txt,file2.txt,file3.txt"
      local matches = { line:match(handler.pattern) }
      local state = {}
      handler:handle(matches, state)
      assert.same({ "file1.txt", "file2.txt", "file3.txt" }, state.readonly_files)
    end)

    it("should handle empty readonly declaration", function()
      local line = "Readonly:"
      local matches = { line:match(handler.pattern) }
      local state = {}
      handler:handle(matches, state)
      assert.same({}, state.readonly_files)
    end)
  end)

  describe("EditableHandler", function()
    local handler = patterns.EditableHandler:new()

    it("should parse single editable file path", function()
      local line = "Editable: path/to/file.txt"
      local matches = { line:match(handler.pattern) }
      local state = {}
      handler:handle(matches, state)
      assert.same({ "path/to/file.txt" }, state.editable_files)
    end)

    it("should parse multiple paths", function()
      local line = "Editable: file1.txt file2.txt file3.txt"
      local matches = { line:match(handler.pattern) }
      local state = {}
      handler:handle(matches, state)
      assert.same({ "file1.txt", "file2.txt", "file3.txt" }, state.editable_files)
    end)
  end)

  describe("FeedbackHandler", function()
    local handler = patterns.FeedbackHandler:new()

    it("should detect feedback prompt", function()
      local line = "Add lua/aider/health.lua to the chat? (Y)es/(N)o/(A)ll/(S)kip all/(D)on't ask again [Yes]"
      local matches = { line:match(handler.pattern) }
      local state = {}
      handler:handle(matches, state)
      assert.equals(
        "Add lua/aider/health.lua to the chat? (Y)es/(N)o/(A)ll/(S)kip all/(D)on't ask again [Yes]",
        state.wait_for_feedback
      )
    end)

    it("should detect feedback prompt which not completed", function()
      local line = "Add lua/aider/health.lua to the chat? (Y)es/(N)o/(A)ll"
      local matches = { line:match(handler.pattern) }
      local state = {}
      handler:handle(matches, state)
      assert.equals("Add lua/aider/health.lua to the chat? (Y)es/(N)o/(A)ll", state.wait_for_feedback)
    end)
  end)
end)
