require 'gserver'
require './core/login.rb'
require './core/user.rb'
require './core/command.rb'

class Connector < GServer

  @@users = []

  def error(detail)
    log("-------------------------------------\n")
    log("Error: #{$!}\n")
    log("Environment: " + current_environment + "\n")
    log("-------------------------------------\n")
    log("Backtrace\n")
    log("-------------------------------------\n")
    detail.backtrace.each do |d|
      log(d)
    end
    log("-------------------------------------\n")
  end

  def read (user, prompt = "> ")
    if prompt
      user.catch_msg prompt
    end

    begin
      line = user.socket.readline.chomp
      io = user.socket

      # poradzenie sobie z kodami telnetowymi na podstawie
      # http://www.rubyquiz.com/quiz32.html
      # by Pat Eyler
      while line.index("\377") # parse Telnet codes
        if line.sub!(/(^|[^\377])\377[\375\376](.)/, "\\1")
          # answer DOs and DON'Ts with WON'Ts
          io.print "\377\374#{$2}"
        elsif line.sub!(/(^|[^\377])\377[\373\374](.)/, "\\1")
          # answer WILLs and WON'Ts with DON'Ts
          io.print "\377\376#{$2}"
        elsif line.sub!(/(^|[^\377])\377\366/, "\\1")
          # answer "Are You There" codes
          io.puts "Still here, yes."
        elsif line.sub!(/(^|[^\377])\377\364/, "\\1")
          # do nothing - ignore IP Telnet codes
        elsif line.sub!(/(^|[^\377])\377[^\377]/, "\\1")
          # do nothing - ignore other Telnet codes
        elsif line.sub!(/\377\377/, "\377")
          # do nothing - handle escapes
        end
      end
      # koniec kodu Pat'a

      Command.new(line)
    rescue
      nil
    end
  end

  def disconnecting(port)
    @@users.each do |u|
      if u.port == port
        puts u.nick + " logged out."
        break
      end
    end

    @@users.delete_if { |x| x.socket.closed? }
    super(port)
  end

  def serve(client)
    client.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

    user = User.new(client)

    @@users.push(user)

    set_current_user(user)

    Engine.instance.welcome(user)
    accplayer = Login.instance.login(user)

    if user.socket.closed?
      return
    end

    puts "Logujemy gracza " + accplayer['name'] + " do gry."
    user.nick = accplayer['name']

    #    user.disconnect()
    player = Player.new(user, accplayer)

    ## jeżeli gracz nie jest jeszcze do końca stworzony, to musi
    ## zostać przeniesiony do specjalnego miejsca, gdzie
    ## postać jest tworzona.

    require './world/room.rb'
    room = World::Room.instance
    player.move(room)
    room.filter(Player, [player]).each do |p|
      p.catch_msg(player.short.capitalize + " wchodzi do gry.\n")
    end

    set_environment("game")
    loop do
      if player.socket.closed?
        break
      end

      command = read(player)
      if command.nil?
        # utracono połączenie, przenosimy do link_dead obiektu
        # .. jak go zakoduje :-) na razie przenosimy do nil, czyli usuwamy ze swiata
        player.move(nil)
        break
      end

      Engine.instance.serve(player, command)
    end
  end

  def self.get_users
    @@users
  end
end
