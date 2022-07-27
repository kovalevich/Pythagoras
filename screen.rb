module Pythagoras
  class BaseScreen
    attr_reader :name, :slug, :buf, :main_column_content, :right_column_content
    attr_accessor :previous, :next, :main_activity, :progress

    def initialize(name, slug)
      @active = false
      @visible = false
      @wait_for_input = false
      @name = name
      @slug = slug
      @for_output = nil
      @buf = []
      @progress = 0

      @main_column_content = []
      @right_column_content = []

      @previous = nil
      @next = nil

      @main_activity = nil
    end

    def main_column(lines)
      @main_column_content = lines
    end

    def clear_buffer
      @buf = []
    end

    def right_column(lines)
      @right_column_content = lines
    end

    def show
      @visible = true
    end

    def hide
      @visible = false
    end

    def visible?
      @visible
    end

    def activate
      @active = true
    end

    def deactivate
      @active = false
    end

    def active?
      @active
    end

    def wait?
      @wait_for_input
    end

    def wait_for_input
      @wait_for_input = true
    end

    def output
      @wait_for_input = false
      @for_output = @buf
      @buf = []
    end

    def out
      ret = @for_output
      @for_output = nil
      ret
    end

    def process_button
      # method should be implemented
    end

    def process_bar(with)
      ''
    end
  end

  class TestScreen < BaseScreen
    def process_button(button)
      return unless @wait_for_input

      @buf << button if button.to_i >= 0 && button.to_i <= 9
      @buf = @buf[0..-2] if button == Curses::KEY_BACKSPACE
      output if button == Curses::KEY_ENTER
    end
  end

  class TrainingScreen < BaseScreen
    def process_button(button)
      return unless @wait_for_input

      @buf << button if button >= 0 && button <= 9
      @buf = @buf[0..-2] if button == Curses::KEY_BACKSPACE
      output if button == Curses::KEY_ENTER
    end
  end
end
