require 'timeout'

module Pythagoras
  class Test
    TEST_SIZE = 100
    TEST_SUCCESS = 95
    TIMEOUT = 15

    def initialize(screen)
      @history = []
      @screen = screen
      @current_state = nil
      @all_tests = []
      @time_target = 0
      @current_time_delay = 0
      run
    end

    def run
      Thread.new do
        loop do
          update_screen
          @history.clear
          @screen.clear_buffer
          set_numbers(state :waiting_for_numbers)

          TEST_SIZE.times do |t|
            @ex = exercise
            if fails_count >= max_fails
              state :waiting_for_confirm_fail
              break
            end
            begin
              @current_time_delay = TIMEOUT
              @time_target = Time.now + TIMEOUT
              user_answer = 0
              Timeout.timeout(TIMEOUT) do
                @screen.clear_buffer
                user_answer = state :waiting_for_answer
              end
              result(user_answer)
            rescue
              result(0)
            end
          end
          state :success if fails_count < max_fails
          save_result
        end
      end
    end

    def save_result
      @all_tests .unshift({
        numbers: @numbers.join('-'),
        ok: successful_count,
        fail: fails_count,
        total: @history.size
      })
    end

    def set_numbers(numbers)
      @numbers = numbers.split(' ').map(&:to_i)
    end

    def state(current_state)
      @current_state = current_state
      case current_state
      when :waiting_for_numbers
        @screen.wait_for_input
        while @screen.wait?
          sleep 0.2
        end
        return @screen.out.join
      when :waiting_for_answer
        @screen.wait_for_input
        update_screen
        while @screen.wait?
          sleep 0.2
        end
        return @screen.out.join.to_i
      when :waiting_for_confirm_fail, :success
        @screen.wait_for_input
        update_screen
        while @screen.wait?
          sleep 0.2
        end
        return
      when :waiting_for_confirm_ok, :waiting_for_confirm
        @current_time_delay = 3
        @time_target = Time.now + 3
        sleep 3
      end
    end

    def update_screen
      @screen.main_column(
        [
          '',
          "#{main_record} #{@screen.buf.join}",
          '',
          '<hr>',
          [:waiting_for_answer, :waiting_for_confirm_ok, :waiting_for_confirm].include?(@current_state) ? lambda { time_progress } : nil
        ].compact
      )
      @screen.right_column([
                             "Всего решено примеров: #{@history.size}",
                             "Правильно решено: #{successful_count}",
                             "Ошибок сделано: #{fails_count}",
                             "Можно сделать ошибок: #{max_fails.to_i}",
                             '',
                             '<hr>',
                             'Результаты последних тестов:',
                           ] + tests_history)
    end

    def main_record
      case @current_state
      when nil, :waiting_for_numbers
        'Введите через пробел числа для теста:'
      when :waiting_for_answer
        "#{@ex.first} * #{@ex.last} ="
      when :success
        "Ура ты прошел тест на числа #{@numbers.join(', ')}. Срочно играть в Dota2"
      when :waiting_for_confirm_fail
        'Ты провалил тест. Нажимай ENTER чтобы попытаться снова'
      when :waiting_for_confirm_ok
        "#{@ex.first} * #{@ex.last} = #{@user_answer} ✔"
      else
        "#{@ex.first} * #{@ex.last} = #{@user_answer} - ОШИБКА! Правильный ответ #{@correct_answer}"
      end
    end

    def time_remaining
      Time.now - @time_target
    end

    def result(user_answer)
      @user_answer = user_answer
      @correct_answer = answer = @ex.inject(&:*)
      unless user_answer == answer
        state :waiting_for_confirm
      else
        state :waiting_for_confirm_ok
      end
      @history.unshift(pair: @ex.sort, success: user_answer == answer, user_answer: user_answer, answer: answer)
      @screen.progress = progress
    end

    def tests_history
      @all_tests[0..10].map do |t|
        "#{t[:numbers]}: #{t[:ok]}/#{t[:total]}"
      end
    end

    def bad_sample
      h = @history[0..100]
      all = h.select do |e|
        !e[:success] && h.count(e) > 3
      end

      all.any? ? all.sample[:pair] : nil
    end

    def time_progress
      100 - ((100.0 / @current_time_delay) * (@current_time_delay + time_remaining)).to_i
    end

    def exercise
      [@numbers.sample, rand(2..9)].shuffle
    end

    def progress
      (100.0 / TEST_SIZE) * @history.size
    end

    def fails_count
      @history.count { |e| !e[:success] }
    end

    def max_fails
      (TEST_SIZE.to_f / 100) * (100 - TEST_SUCCESS)
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
