require 'singleton'
require './core/modules/command'

module Cmd
  module Live
    class Wiz
      include Singleton
      include Modules::Command

      def shutdown(command, this_player)
        shall_i_restart(false)
        p "Server shutdown executed in-game"
        EventMachine::stop_event_loop
      end

      def reboot(command, this_player)
        p "Server reboot, executed in-game"
        EventMachine::stop_event_loop
      end

      def load(command, tp)
        unless command.has_args?
          tp.fail_message = "load [file]?"
          return false
        end

        file = Dir.pwd + "/" + command.args.join(" ")

        tp.catch_msg("Trying to load "+ file + "... ")

        if File.exist?(file)
          if File.file?(file)
            ## make it simplier, plz...
            sp = command.args.join.split("/")
            filename = sp.pop
            sp = sp.map(&:capitalize).join("::")
            filename = filename[0..filename.length - 4]
            filename = filename.capitalize
            sp = sp.constantinize
            binding.pry
            if sp.send(:const_defined?, filename.to_sym)
              log_notice("[wiz::load] - removing constant #{sp.to_s}::#{filename}")
              sp.send(:remove_const, filename.to_sym)
            end

            super(file)
            tp.catch_msg("loaded!\n")
          else
            tp.catch_msg("fail! (file is a directory)\n")
          end
        else
          tp.catch_msg("fail! (file not found)\n")
        end

        return true
      end

      def ls(command, this_player)
        dir = Dir.pwd + "/world"
        this_player.catch_msg(dir + "\n")

        entries = Dir.entries(dir)
        entries.map! do |f|
          if File.is_loaded?(dir + "/" + f)
            f += "*"
          else
            f
          end
        end

        this_player.catch_msg(entries.join("  "))
        this_player.catch_msg("\n")
      end

      def pry(command, tp)
        Thread.new do
          binding.pry
        end.join
      end

      def exec(command, tp)
        exec_str = command.args.join(" ")
        begin
          tp.catch_msg("----------------------------\n")
          tp.catch_msg("Executing: #{exec_str}\n")
          tp.catch_msg("----------------------------\n")
          tp.catch_msg(eval(exec_str))
          tp.catch_msg("\n")
          tp.catch_msg("----------------------------\n")
        rescue Exception => e
          tp.catch_msg("Error: #{$!}\n")
          e.backtrace.each do |msg|
            tp.catch_msg("#{msg}\n")
          end
        end
      end

      def init
        init_module_command

        add_object_action(:load, "load")
        add_object_action(:ls, "ls")
        add_object_action(:pry, "pry")
        add_object_action(:exec, "exec")

        add_object_action(:shutdown, "shutdown")
        add_object_action(:reboot, "reboot")
      end
    end
  end
end
