local patterns = require("aider.patterns")
local terminal_events = require("aider.terminal_events")

describe("terminal_events PATTERNS", function()
  before_each(function()
    terminal_events.reset_state()
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
