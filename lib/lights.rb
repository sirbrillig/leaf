module Leaf

  class VisibleArea < Chingu::GameObject
    trait :collision_detection
    trait :bounding_circle, :scale => 1.1, :debug => Leaf::DEBUG
    attr_accessor :handle_collide_far, :handle_collide_middle, :handle_collide_close, :handle_collide_distant, :holder
    attr_accessor :handle_seen_far, :handle_seen_middle, :handle_seen_close, :handle_seen_distant
    attr_accessor :targets

    #FIXME: make light of different shapes, ie: a cone for the guards.
    #FIXME: make different shaped-light use appropriate collision to determine
    #what happens.

    def setup
      self.zorder = Leaf::Level::LIGHTED_LAYER
      self.rotation_center = :center
      @image = Gosu::Image["media/visiblearea.png"]
      self.mode = :add
      self.alpha = 250
      self.radius = 352

      @tracked_objects = {:close => [], :middle => [], :far => [], :distant => []}
      @show_detection_area = false # For debugging
      @caching = false
    end

    def distant_radius
      self.radius
    end

    def far_radius
      self.radius - (self.radius / 4)
    end

    def middle_radius
      self.radius - (self.radius / 2)
    end

    def close_radius
      self.radius - ((self.radius / 4) * 3)
    end

    def follow(sprite)
      self.x = sprite.x
      self.y = sprite.y
    end

    # Simulate a bounding_box by using the dimensions of the circle.
    def bb
      @cached_rect if @cached_rect
      @cached_rect = Chingu::Rect.new(self.x - self.radius, self.y - self.radius, self.radius * 2, self.radius * 2)
    end

    # Return the range area (:close, :middle, :far) of the object.
    def range_to(object)
      distance = game_state.distance(self, object)
      case distance
      when (middle_radius + 1)..far_radius
        return :far
      when (close_radius + 1)..middle_radius
        return :middle
      when 0..close_radius
        return :close
      when (far_radius + 1)..distant_radius
        return :distant
      else
        return nil
#         raise "Distance (#{distance}) [and possibly Radius (#{self.radius})] is too large for my range (300) when checking distance between #{self.class} and #{object.class}."
      end
    end

    # Return true if we have line-of-sight to object.
    def line_of_sight_to(object)
      @holder ||= self
      @targets ||= []
      @targets.clear
      @targets << object unless @targets.include? object
      return false if game_state.game_object_map.object_between?(@holder, object, only: Leaf::BlocksVision)
      return true
    end

    def cached?(object, distance)
      return false unless @caching
      @tracked_objects[distance].include? object
    end

    def cache(object, distance)
      return nil unless @caching
      @tracked_objects.each_key { |key| @tracked_objects[key].delete(object) }
      @tracked_objects[distance] << object
    end

    def draw
      super
      if true #Leaf::DEBUG
        @targets and @targets.each do |target| 
          game_state.game_object_map.grid_spaces_between(@holder, target).each do |sq| 
            break if game_state.game_object_map.game_object_at(sq[0], sq[1]).is_a? Leaf::BlocksVision
            game_state.draw_rect(Chingu::Rect.new(sq[0] * game_state.grid[0], sq[1] * game_state.grid[1], 10, 10), Gosu::Color::GREEN, Leaf::Level::LIGHTED_LAYER)
          end
        end
      end
      if @show_detection_area
        game_state.draw_circle(self.x, self.y, close_radius, Gosu::Color.new(0xff00ff00))
        game_state.draw_circle(self.x, self.y, middle_radius, Gosu::Color.new(0xff00ff00))
        game_state.draw_circle(self.x, self.y, far_radius, Gosu::Color.new(0xff00ff00))
        game_state.draw_circle(self.x, self.y, distant_radius, Gosu::Color.new(0xff00ff00))
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
      @image = nil
#       self.hide! # Not sure if it's better to be visible.
      @show_detection_area = false # For debugging
      @caching = false 
    end

    def update
      self.each_collision(Guard, Watcher) do |area, object|
        range = self.range_to(object)
        los = line_of_sight_to(object)
        update_object_visibility(object, range) if los
        delegate_collision_with(object, range, los)
      end
    end

    def delegate_collision_with(object, range, line_of_sight)
      seen = line_of_sight # Objects without facing are considered to look in all directions.
      if line_of_sight and object.respond_to? :facing_toward
        seen = false 
        seen = true if object.facing_toward(self)
      end

      case range
      when :far
        unless cached?(object, :far)
          cache(object, :far)
          handle_collide_far.call(object) if handle_collide_far
          handle_seen_far.call(object) if seen and handle_seen_far
        end
      when :middle
        unless cached?(object, :middle)
          cache(object, :middle)
          handle_collide_middle.call(object) if handle_collide_middle
          handle_seen_middle.call(object) if seen and handle_seen_middle
        end
      when :close
        unless cached?(object, :close)
          cache(object, :close)
          handle_collide_close.call(object) if handle_collide_close
          handle_seen_close.call(object) if seen and handle_seen_close
        end
      when :distant
        unless cached?(object, :distant)
          cache(object, :distant)
          handle_collide_distant.call(object) if handle_collide_distant
          handle_seen_distant.call(object) if seen and handle_seen_distant
        end
      end
    end

  end # DetectionArea

end # Leaf
