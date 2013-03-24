module Std
  class Living < Std::Container
    attr_accessor :fail_message

    def initialize(*args)
      super(*args)


      @souls = []

      @souls << Cmd::Live::Standard.instance
      @souls << Cmd::Live::Exits.instance
      @souls << Cmd::Live::Items.instance
      @souls << Cmd::Live::Social.instance

      update_hooks

      @handler = GameHandler.new(nil)
      @handler.init(self)
      @fail_message = ""
    end

    def update_hooks
      @souls.each {|soul| soul.init(self) }
    end

    def get_souls
      @souls
    end

    def is_player?
      false
    end

    def set_random_move(seconds)
      @random_move_alarm = Alarm.new.repeat(seconds, seconds) do
        if environment
          ex = environment.get_exits.collect {|exit| exit[:direction]}.sample
          command(ex)
        end
      end
    end

    def catch_msg(msg, newline = false)
    end

    def command(command)
      @handler.input(command)
    end

    def __destruct__
      if @random_move_alarm
        @random_move_alarm.stop
      end
      :killed
    end
  end
end