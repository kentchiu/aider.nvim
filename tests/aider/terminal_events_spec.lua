local terminal_events = require("aider.terminal_events")

describe("terminal_events", function()
  before_each(function()
    -- Reset the state before each test
    terminal_events.reset_state()
  end)

  describe("check_readonly", function()
    it("should parse single readonly file path", function()
      local result = terminal_events.check_readonly("Readonly: path/to/file.txt")
      assert.is_true(result)
      assert.same({ "path/to/file.txt" }, terminal_events.get_readonly_files())
    end)

    it("should parse multiple readonly file paths", function()
      local result = terminal_events.check_readonly("Readonly: file1.txt file2.txt file3.txt")
      assert.is_true(result)
      assert.same({ "file1.txt", "file2.txt", "file3.txt" }, terminal_events.get_readonly_files())
    end)

    it("should handle paths with spaces", function()
      local result = terminal_events.check_readonly("Readonly: path/to/my file.txt another file.txt")
      assert.is_true(result)
      assert.same({ "path/to/my", "file.txt", "another", "file.txt" }, terminal_events.get_readonly_files())
    end)

    it("should handle empty readonly line", function()
      local result = terminal_events.check_readonly("Readonly:")
      assert.is_true(result)
      assert.same({}, terminal_events.get_readonly_files())
    end)

    it("should return false for non-readonly lines", function()
      local result = terminal_events.check_readonly("Some other text")
      assert.is_false(result)
      assert.same({}, terminal_events.get_readonly_files())
    end)

    it("should handle comma-separated paths", function()
      local result = terminal_events.check_readonly("Readonly: file1.txt,file2.txt,file3.txt")
      assert.is_true(result)
      assert.same({ "file1.txt", "file2.txt", "file3.txt" }, terminal_events.get_readonly_files())
    end)
  end)

  describe("check_editable", function()
    it("should parse single editable file path", function()
      local result = terminal_events.check_editable("editable> path/to/file.txt")
      assert.is_true(result)
      assert.same({ "path/to/file.txt" }, terminal_events.get_editable_files())
    end)

    it("should parse multiple editable file paths", function()
      local result = terminal_events.check_editable("editable> file1.txt file2.txt file3.txt")
      assert.is_true(result)
      assert.same({ "file1.txt", "file2.txt", "file3.txt" }, terminal_events.get_editable_files())
    end)

    it("should handle paths with spaces", function()
      local result = terminal_events.check_editable("editable> path/to/my file.txt another file.txt")
      assert.is_true(result)
      assert.same({ "path/to/my", "file.txt", "another", "file.txt" }, terminal_events.get_editable_files())
    end)

    it("should handle empty editable line", function()
      local result = terminal_events.check_editable("editable>")
      assert.is_true(result)
      assert.same({}, terminal_events.get_editable_files())
    end)

    it("should return false for non-editable lines", function()
      local result = terminal_events.check_editable("Some other text")
      assert.is_false(result)
      assert.same({}, terminal_events.get_editable_files())
    end)

    it("should handle comma-separated paths", function()
      local result = terminal_events.check_editable("editable> file1.txt,file2.txt,file3.txt")
      assert.is_true(result)
      assert.same({ "file1.txt", "file2.txt", "file3.txt" }, terminal_events.get_editable_files())
    end)
  end)

  describe("check_chat_mode", function()
    it("should detect code mode", function()
      local result = terminal_events.check_chat_mode("> ")
      assert.equals("code", terminal_events.get_current_mode())
    end)

    it("should detect ask mode", function()
      local result = terminal_events.check_chat_mode("ask> ")
      assert.equals("ask", terminal_events.get_current_mode())
    end)

    it("should detect architect mode", function()
      local result = terminal_events.check_chat_mode("architect> ")
      assert.equals("architect", terminal_events.get_current_mode())
    end)

    it("should trigger mode change callback", function()
      local callback_called = false
      local new_mode = nil
      terminal_events.on_mode_change(function(mode)
        callback_called = true
        new_mode = mode
      end)

      terminal_events.check_chat_mode("ask> ")
      assert.is_true(callback_called)
      assert.equals("ask", new_mode)
    end)

    it("should not trigger callback if mode hasn't changed", function()
      local callback_count = 0
      terminal_events.on_mode_change(function(mode)
        callback_count = callback_count + 1
      end)

      terminal_events.check_chat_mode("ask> ")
      terminal_events.check_chat_mode("ask> ")
      assert.equals(1, callback_count)
    end)

    it("should handle non-mode lines", function()
      local initial_mode = terminal_events.get_current_mode()
      terminal_events.check_chat_mode("some random text")
      assert.equals(initial_mode, terminal_events.get_current_mode())
    end)
  end)
end)
