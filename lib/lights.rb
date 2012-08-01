module Leaf

  class VisibleArea < Chingu::GameObject
    trait :collision_detection
    trait :bounding_circle, :scale => 1.1, :debug => Leaf::DEBUG
    attr_accessor :handle_collide_far, :handle_collide_middle, :handle_collide_close, :handle_collide_distant

    CLOSE_RADIUS = 80
    MIDDLE_RADIUS = 200
    FAR_RADIUS = 290
    DISTANT_RADIUS = 351

    def setup
      self.zorder = Leaf::Level::LIGHTED_LAYER
      self.rotation_center = :center
      @image = nil#Gosu::Image["media/visiblearea.png"]
      self.alpha = 40
      self.radius = 300

      @tracked_objects = {:close => [], :middle => [], :far => [], :distant => []}
      @show_detection_area = false # For debugging
    end

    def follow(sprite)
      self.x = sprite.x
      self.y = sprite.y
    end

    # Simulate a bounding_box by using the dimensions of the circle.
    def bb
      @cached_rect if @cached_rect
      @cached_rect = Rect.new(self.x - self.radius, self.y - self.radius, self.radius * 2, self.radius * 2)
    end

    # Return the range area (:close, :middle, :far) of the object.
    def range_to(object)
      distance = game_state.distance(self, object)
      case distance
      when (MIDDLE_RADIUS + 1)..FAR_RADIUS
        return :far
      when (CLOSE_RADIUS + 1)..MIDDLE_RADIUS
        return :middle
      when 0..CLOSE_RADIUS
        return :close
      when (FAR_RADIUS + 1)..DISTANT_RADIUS
        return :distant
      else
        return nil
#         raise "Distance (#{distance}) [and possibly Radius (#{self.radius})] is too large for my range (300) when checking distance between #{self.class} and #{object.class}."
      end
    end

    # Return true if we have line-of-sight to object.
    def line_of_sight_to(object)
      # FIXME: line-of-sight should be blocked by solid objects (Platforms).
      game_state.game_object_map.each_object_between(self, object) { return false }
      true
    end

    def draw
      super
      if @show_detection_area
        game_state.draw_circle(self.x, self.y, CLOSE_RADIUS, Gosu::Color.new(0xff00ff00))
        game_state.draw_circle(self.x, self.y, MIDDLE_RADIUS, Gosu::Color.new(0xff00ff00))
        game_state.draw_circle(self.x, self.y, FAR_RADIUS, Gosu::Color.new(0xff00ff00))
        game_state.draw_circle(self.x, self.y, DISTANT_RADIUS, Gosu::Color.new(0xff00ff00))
        game_state.draw_rect(bb, Gosu::Color.new(0xff00ff00), Leaf::Level::LIGHTED_LAYER)
      end
    end

    def delegate_collision_with(object, range)
      case range
      when :far
        unless @tracked_objects[:far].include? object
          @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
          #             @tracked_objects[:far] << object
          object.alpha = Leaf::Level::FAR_OBJECT_ALPHA
          object.hidden = false if object.is_a? Hidable
          handle_collide_far.call(object) if handle_collide_far
        end
      when :middle
        unless @tracked_objects[:middle].include? object
          @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
          # FIXME: this caching mechanism keeps hiding from working
          #             @tracked_objects[:middle] << object
          object.alpha = Leaf::Level::MIDDLE_OBJECT_ALPHA
          object.hidden = false if object.is_a? Hidable
          handle_collide_middle.call(object) if handle_collide_middle
        end
      when :close
        unless @tracked_objects[:close].include? object
          @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
          #             @tracked_objects[:close] << object
          object.alpha = Leaf::Level::CLOSE_OBJECT_ALPHA
          object.hidden = false if object.is_a? Hidable
          handle_collide_close.call(object) if handle_collide_close
        end
      when :distant
        unless @tracked_objects[:distant].include? object
          @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
#           @tracked_objects[:distant] << object
          object.alpha = Leaf::Level::FAR_OBJECT_ALPHA
          object.hidden = true if object.is_a? Hidable
          handle_collide_distant.call(object) if handle_collide_distant
        end
        #         else
        #           raise "Range was not what I expected between #{self.class} and #{object.class}. range=#{range}"
      end
    end

    def update
      self.each_collision(Guard, Watcher) do |area, object|
        range = :distant
        range = self.range_to(object) if line_of_sight_to(object)
        delegate_collision_with(object, range)
      end
    end
  end # VisibleArea

  class DetectionArea < VisibleArea
    def setup
      super
#       self.hide! # Not sure if it's better to be visible.
    end
  end # DetectionArea

end # Leaf
