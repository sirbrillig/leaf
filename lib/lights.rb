module Leaf

  class VisibleArea < Chingu::GameObject
    trait :collision_detection
    trait :bounding_circle, :scale => 1.1, :debug => Leaf::DEBUG
    attr_accessor :handle_collide_far, :handle_collide_middle, :handle_collide_close, :handle_collide_distant, :holder

    CLOSE_RADIUS = 80
    MIDDLE_RADIUS = 200
    FAR_RADIUS = 290
    DISTANT_RADIUS = 351

    #FIXME: make light of different shapes, ie: a cone for the guards.
    #FIXME: make different shaped-light use appropriate collision to determine
    #what happens.

    def setup
      self.zorder = Leaf::Level::LIGHTED_LAYER
      self.rotation_center = :center
      @image = Gosu::Image["media/visiblearea.png"]
      self.mode = :add
      self.alpha = 200
      self.radius = DISTANT_RADIUS + 1

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
      @holder ||= self
      game_state.game_object_map.each_object_between(@holder, object) { return false } 
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

    def update
      self.each_collision(Guard, Watcher) do |area, object|
        range = self.range_to(object)
        update_object_visibility(object, range)
      end
    end

    private
    def update_object_visibility(object, range)
      return unless object.is_a? Hidable
      return unless object.hidden?
      object.hidden = false
    end
  end # VisibleArea

  class DetectionArea < VisibleArea
    def setup
      super
      self.hide! # Not sure if it's better to be visible.
    end

    def update
      self.each_collision(Guard, Watcher) do |area, object|
        range = self.range_to(object)
        update_object_visibility(object, range) if line_of_sight_to(object)
        delegate_collision_with(object, range)
      end
    end

    def delegate_collision_with(object, range)
      case range
      when :far
        unless @tracked_objects[:far].include? object
          @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
          @tracked_objects[:far] << object
          handle_collide_far.call(object) if handle_collide_far
        end
      when :middle
        unless @tracked_objects[:middle].include? object
          @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
          @tracked_objects[:middle] << object
          handle_collide_middle.call(object) if handle_collide_middle
        end
      when :close
        unless @tracked_objects[:close].include? object
          @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
          @tracked_objects[:close] << object
          handle_collide_close.call(object) if handle_collide_close
        end
      when :distant
        unless @tracked_objects[:distant].include? object
          @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
          @tracked_objects[:distant] << object
          handle_collide_distant.call(object) if handle_collide_distant
        end
      end
    end

  end # DetectionArea

end # Leaf
