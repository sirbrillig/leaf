module Leaf
  class Level < Chingu::GameState
    traits :viewport, :timer
    attr_reader :player, :game_object_map

    def initialize(options={})
      super

      on_input(:e, :edit)
      on_input(:escape, :exit)
      on_input(:q, :exit)

      self.viewport.game_area = [0, 0, 2048, 768]

      @file = File.join("#{self.class.name.split('::').last.to_s.downcase}.yml")
      load_game_objects(:file => @file, :debug => true)

      @player = Leaf::Player.create(:x => 70, :y => 200)

      @grid = [50, 50]
      self.viewport.lag = 0.95
    end

    def setup
      @game_object_map = Chingu::GameObjectMap.new(:game_objects => Platform.all, :grid => @grid)
    end

    def edit
      push_game_state(Chingu::GameStates::Edit.new(:grid => @grid, :file => @file, :snap_to_grid => true, :except => [Player]))
    end

    def draw
      fill(Gosu::Color::BLACK)
      super
    end

    def update
      super
      self.viewport.x_target = @player.x - $window.width/2
      $window.caption = "Leaf"
    end
  end # Level

class Level1 < Level; end

end # Leaf

