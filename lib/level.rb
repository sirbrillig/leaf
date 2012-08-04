module Leaf
  class Level < Chingu::GameState
    traits :viewport, :timer
    attr_reader :player, :game_object_map, :background_object_map

    OVERLAY_LAYER = 200
    SPRITES_LAYER = 100
    PLATFORM_LAYER = 15
    LIGHTED_LAYER = 10
    BACKGROUND_OBJECT_LAYER = 8
    BACKGROUND_LAYER = 5

    DARKNESS_ALPHA = 150
    FAR_OBJECT_ALPHA = 255
    MIDDLE_OBJECT_ALPHA = 255
    CLOSE_OBJECT_ALPHA = 255

    # FIXME: darkness is removed only by light sources

    def load_map
      @file = File.join("maps/#{self.class.name.split('::').last.to_s.downcase}.yml")
      load_game_objects(:file => @file, :debug => Leaf::DEBUG)

      @background = Leaf::Background.create(:x => 600, :y => 400)

      @player = Leaf::Player.create(:x => 95, :y => 50)

      @grid = [5, 5]
      self.viewport.lag = 0.95
      puts "level created"
    end

    def setup
      on_input(:e, :edit)
      on_input(:escape, :exit)
      on_input(:q, :exit)

      self.viewport.game_area = [0, 0, 2048, 768]
      load_map

      @game_object_map = Chingu::GameObjectMap.new(:game_objects => Platform.all + BackgroundPlatform.all, :grid => @grid)
      @background_object_map = Chingu::GameObjectMap.new(:game_objects => Tree.all, :grid => @grid)
    end

    def destroy_all_objects
      #FIXME: remember to list all objects here.
      #FIXME: do we need to list Platforms, etc, too?
      objects = [Player, Guard, Watcher]
      objects.each do |obj|
        obj.destroy_all
      end
    end

    def edit
      push_game_state(LevelEditor.new(:grid => @grid, :file => @file, :snap_to_grid => false, :except => [Background, BackgroundObject, Player, Creature, Enemy, DetectionArea, VisibleArea, MovementBehavior]))
    end

    def update
      super
      self.viewport.x_target = @player.x - $window.width/2
      $window.caption = "Leaf"
    end

    def died
      destroy_all_objects 
      switch_game_state(GameOver)
    end

    # Return the distance in pixels between two points A and B on the x/y grid. 
    def distance(a, b)
      Math.sqrt(((a.x - b.x) ** 2) + ((a.y - b.y) ** 2).abs)
    end
  end # Level

class Level1 < Level; end
class Level2 < Level; end

end # Leaf

