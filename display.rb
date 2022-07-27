module Pythagoras
  class Display
    COLUMN_1_WIDTH = 16
    COLUMN_3_WIDTH = 35

    def initialize(window, rows, cols)
      @window = window
      @rows, @cols = rows, cols
    end

    def show(menu)
      @rows_wrote = { col1: 1, col2: 1, col3: 1 }
      @window.clear
      menu.active_screen&.main_activity&.update_screen
      show_borders
      show_header(menu)
      @rows_wrote.transform_values! { |v| v + 1 }
      show_menu(menu)
      show_main_column(menu)
      show_right_column(menu)
      @window.setpos(@rows - 1, @cols - 1)
      @window.refresh
    end

    def show_borders
      0.upto(@rows-1) do |r|
        @window.setpos(r, COLUMN_1_WIDTH)
        @window << '|'
        @window.setpos(r, @cols - COLUMN_3_WIDTH - 2)
        @window << '|'
      end
      @window.box('|', '-')
      @window.setpos(2, 1)
      @window << '-' * (@cols - 2)
    end

    def show_header(menu)
      col1('МЕНЮ')
      col2 menu.activated? ? 'Выбери нужный пункт меню и нажми ENTER' : menu.visible_screen.name + '  ' + progress_bar(menu.visible_screen.progress, @cols - COLUMN_1_WIDTH - COLUMN_3_WIDTH - 20)
      col3 'Твои успехи'
    end

    def progress_bar1(with)
      with -= (@name.size + 5)
      text = '   '
      text += '█' * ((with.to_f / 100) * @progress).to_i
      text = format("%-#{with}s", text)
      text += "#{@progress.to_s}%" if @progress < 98
      text
    end

    def progress_bar(progress, with, symbol: '█', percentage: true)
      text = ''
      text += symbol * ((with.to_f / 100) * progress).to_i
      text = format("%-#{with}s", text)
      text += "#{progress.to_s}%" if percentage && progress < 98
      text
    end

    def show_main_column(menu)
      return unless menu.visible_screen.active?

      content = menu.active_screen.main_column_content
      content.each { |text| col2 text }
    end

    def show_right_column(menu)
      return unless menu.visible_screen.active?

      content = menu.active_screen.right_column_content
      content.each { |text| col3 text }
    end

    def show_menu(menu)
      items = menu.items
      items.each { |item| col1 item }
    end

    def print(pythagoras)
      # --------------------------------------------------------------------------------------
      # | МЕНЮ:           | Тренировка                  | Твои успехи                        |
      # |-----------------|-------------------------------------------------------------------
      # |     Тест        | 2 + 2 =                     | Тренировок пройдено: 2             |
      # |     Статистика  |                             | Время тренировок: 30 мин           |
      # | --> Тренировка  |                             | Всего примеров решено: 300         |
      # |                 |                             | Решено верно: 200                  |
      # |                 |                             | Решено не верно                    |
      # |                 |                             | Процент успеха                     |
      # |                 |                             | Сегодня:
      # |                 |                             |------------------------
      # |                 |                             |
      # |                 |                             |
      lines = []
      lines << '-' * @cols
      lines << "#{col1('МЕНЮ')}#{col2('Тренировка')}#{col3('Твои успехи')}|"
      lines << '-' * @cols

      (@rows - lines.size - 2).times do |l|
        lines << "#{col1(pythagoras[:col1][l])}#{col2(pythagoras[:col2][l])}#{col3(pythagoras[:col3][l])}|"
      end

      (@rows - lines.size - 2).times { lines << "#{col1}#{col2}#{col3}|" }
      lines << '-' * @cols
      puts lines.join("\n")
    end

    def col1(text = '')
      @window.setpos(@rows_wrote[:col1], 2)
      @window << text
      @rows_wrote[:col1] += 1
    end

    def col2(text = '')
      @window.setpos(@rows_wrote[:col2], 2 + COLUMN_1_WIDTH)
      case text
      when Proc
        @window << progress_bar(text.call, @cols - COLUMN_1_WIDTH - COLUMN_3_WIDTH - 10, symbol: '▃', percentage: false)
      when '<hr>'
        @window.setpos(@rows_wrote[:col2], 1 + COLUMN_1_WIDTH)
        @window << '-' * (@cols - COLUMN_1_WIDTH - COLUMN_3_WIDTH - 3)
      else
        @window << text
      end

      @rows_wrote[:col2] += 1
    end

    def col3(text = '')
      @window.setpos(@rows_wrote[:col3], @cols - COLUMN_3_WIDTH)
      case text
      when Proc
        @window << (text.call).to_s
      when '<hr>'
        @window.setpos(@rows_wrote[:col3], @cols - COLUMN_3_WIDTH - 1)
        @window << '-' * (COLUMN_3_WIDTH)
      else
        @window << text
      end
      @rows_wrote[:col3] += 1
    end

    def str2column(text, with)
      format("| %-#{with}s", text)
    end

    def winsize
      require 'io/console'
      IO.console.winsize
    rescue LoadError
      # This works with older Ruby, but only with systems
      # that have a tput(1) command, such as Unix clones.
      [Integer(`tput li`), Integer(`tput co`)]
    end
  end
end
