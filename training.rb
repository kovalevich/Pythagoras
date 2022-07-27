module Pythagoras
  class Training
    GOALS_PER_DAY = {
      history: 150,
      successful: 95
    }

    def initialize(screen)
      @history = []
      @screen = screen
      run
    end

    def run
      Thread.new do
        loop do
          @ex = exercise
          @screen.clear_buffer
          update_screen
          user_answer = state :waiting_for_answer
          result(user_answer)
        end
      end
    end

    def state(current_state)
      case current_state
      when :waiting_for_answer
        @screen.wait_for_input
        while @screen.wait?
          sleep 0.2
        end
        return @screen.out.join.to_i
      end
    end

    def update_screen
      @screen.main_column(
        [
          '',
          "#{@ex.first} * #{@ex.last} = #{@screen.buf.join}",
          '',
          '<hr>',
          ''
        ] + historical_exercises
      )
      @screen.right_column([
        "Всего решено примеров: #{@history.size}",
        "Правильно решено: #{successful_count}",
        "Правильных решений: #{successful_percentage.round(1)}%"
      ])
    end

    def historical_exercises
      @history[0..10].map do |h|
        text = "#{h[:pair][0]} * #{h[:pair][1]} = #{h[:user_answer]}"
        text += " - ОШИБКА! Правильный ответ: #{h[:answer]}" unless h[:success]
        text
      end
    end

    def result(user_answer)
      answer = @ex.inject(&:*)
      @history.unshift(pair: @ex.sort, success: user_answer == answer, user_answer: user_answer, answer: answer)
      @screen.progress = progress
    end

    def bad_sample
      h = @history[0..100]
      all = h.select do |e|
        !e[:success] && h.count(e) > 3
      end

      all.any? ? all.sample[:pair] : nil
    end

    def exercise
      bad_sample || [rand(2..9), rand(2..9)]
    end

    def progress
      [
        (100.0 / GOALS_PER_DAY[:history]) * @history.size * (successful_percentage.to_f / 100),
      #((100.0 / GOALS_PER_DAY[:successful]) * successful_percentage) * (@history.size > 50 ? 1 : 0)
      ].max.to_i
    end

    def successful_count
      @history.count { |e| e[:success] }
    end

    def successful_percentage
      return 0 if successful_count.zero?

      (100.0 / @history.size) * successful_count
    end
  end
end
