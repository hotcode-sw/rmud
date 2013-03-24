# coding: utf-8
class LoginPlayerHandler < Handler
  def init(player)
    @player = player
    @state = :password_input
  end
  
  def prompt
    case @state
    when :password_input then
      echo_off
      "Podaj haslo: "
    when :password_input_2nd_try then
      echo_off
      "Podaj haslo: "
    else
      "Powazny blad... ?"
    end
  end
  
  def input(data)
    echo_on
    send(@state, data.to_c)
  end

  def password_input(data)
    if Digest::SHA1.hexdigest(data.cmd) != @player.account.player_password
      oo("Haslo jest niepoprawne, sprobuj wpisac ponownie.")
      @state = :password_input_2nd_try
    else
      login_success
    end
  end

  def password_input_2nd_try(data)
    if Digest::SHA1.hexdigest(data.cmd) != @player.account.player_password
      oo("Haslo jest niepoprawne, do zobaczenia!")
      @player_connection.disconnect
    else
      login_success
    end
  end

  def login_success
    player = Std::Player.new(@player_connection, @player.id)
    room   = World::Rooms::Room.instance
    player.move(room)
    @player_connection.input_handler = GameHandler.new(@player_connection)
    @player_connection.input_handler.init(player)
  end
end
