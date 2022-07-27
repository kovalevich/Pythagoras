require 'json'
require 'curses'
require_relative 'display'
require_relative 'screen'
require_relative 'training'
require_relative 'test'

module Curses
  KEY_UP = 'A'
  KEY_DOWN = 'B'
  KEY_RIGHT = 'C'
  KEY_LEFT = 'D'
  KEY_ENTER = 10
  KEY_BACKSPACE = 127
end

module Pythagoras
  class Program
    STORE_FILE = 'save'

    def initialize
      @screens = []
      create_test_screen
      create_training_screen
      @menu = Menu.new(@screens)
      @menu.activate

      @last_button = nil

      Curses.init_screen
      @window = Curses::Window.new(*frame)
      @window.box('|', '-')
      @window.refresh
      @display = Display.new(@window, Curses.lines, Curses.cols)
      Thread.new do
        loop do
          @display.show(@menu)
          sleep 0.2
        end
      end
      run
      @window.close
    end

    def run
      loop do
        ch = @window.getch
        process_action ch
        break if @menu.exit
      end
    end

    def create_test_screen
      screen = TestScreen.new('Тест', 'test')
      @test = Test.new(screen)
      screen.main_activity = @test
      add_screen screen
    end

    def create_training_screen
      screen = TestScreen.new('Тренировка', 'training')
      @training = Training.new(screen)
      screen.main_activity = @training
      add_screen screen
    end

    def add_screen(screen)
      @screens << screen
    end

    def process_action(button)
      @menu.activated? ? process_menu(button) : process_screen(button)

      #@display.show(@menu)
      @window.setpos(0, 0)
    end

    def process_menu(button)
      case button
      when Curses::KEY_UP
        @menu.up
      when Curses::KEY_DOWN
        @menu.down
      when Curses::KEY_LEFT, Curses::KEY_RIGHT, Curses::KEY_ENTER
        @menu.deactivate
      end
    end

    def process_screen(button)
      return @menu.activate if [Curses::KEY_LEFT, Curses::KEY_RIGHT].include? button

      @menu.active_screen.process_button button
    end

    def frame
      [Curses.lines, Curses.cols, 0, 0]
    end

    class << self
      def read_state
        filename = "#{__dir__}/#{STORE_FILE}"
        return unless File.exist? filename

        data = File.binread filename
        Marshal.load(data)
      end

      def save_state(pythagoras)
        filename = "#{__dir__}/#{STORE_FILE}"
        File.open(filename, 'wb') { |f| f.write(Marshal.dump(pythagoras)) }
      end
    end
  end

  class Menu
    attr_reader :visible_screen, :active_screen, :exit

    def initialize(screens)
      @activated = false
      @screens = screens
      @exit = false

      screens << BaseScreen.new('Выход', 'exit')
      screens.size.times do |i|
        screens[i].previous = screens[i - 1]
        screens[i].next = screens[(i == screens.size - 1) ? 0 : i + 1]
      end
      current = screens.find(&:visible?)
      unless current
        current = @screens.first
        current.activate
        current.show
      end
      @visible_screen = current
      @active_screen = current
    end

    def items
      @screens.map do |screen|
        (screen.visible? ? '--> ' : '    ') + screen.name
      end
    end

    def activated?
      @activated
    end

    def up
      current = visible_screen
      hide_all_screens
      current.previous.show
    end

    def down
      current = visible_screen
      hide_all_screens
      current.next.show
    end

    def visible_screen
      @screens.find(&:visible?)
    end

    def active_screen
      @screens.find(&:active?)
    end

    def hide_all_screens
      @screens.each(&:hide)
    end

    def deactivate_all_screens
      @screens.each(&:deactivate)
    end

    def activate
      deactivate_all_screens
      @activated = true
    end

    def deactivate
      @exit = visible_screen.slug == 'exit'
      visible_screen.activate
      @activated = false
    end
  end
end
