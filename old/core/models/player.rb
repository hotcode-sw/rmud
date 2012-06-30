module Models
  class Player
    include DataMapper::Resource

    storage_names[:default] = 'players'

    property :id,         Serial
    belongs_to :account
    property :name,       String
    property :created,    Boolean
    timestamps :created_at
    belongs_to :declension, 'Declension', 
      :parent_key => 'nazwa', :child_key => 'declension_nazwa', 
      :required => false, :default => nil


    has n, :options, :through => :option_players
    has n, :banishes

    def get_by_name(name)
      Models::Player.first(:name => name)
    end

#    def get_option(player_id, option_name)
#      query = "select value from players_options
#        left join options on (players_options.option_id = options.id)
#        where players_options.player_id = ? AND options.name = ? LIMIT 1"
#      @sql.one(query, player_id, option_name)
#    end
  end
end