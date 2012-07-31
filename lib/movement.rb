module Leaf
  module MovementBehaviors
    attr_accessor :movement_behaviors, :noticed_behaviors, :alert_behaviors

    def define_movement(&block)
      self.movement_behaviors = []
      block.call
    end

    def if_noticed(&block)
      self.noticed_behaviors = []
      @recording_noticed_behavior = true
      block.call
      @recording_noticed_behavior = false
    end

    def if_alert(&block)
      self.alert_behaviors = []
      @recording_alert_behavior = true
      block.call
      @recording_alert_behavior = false
    end

    def play_next_movement
      # Silently fail if no movements are defined.
      return if self.movement_behaviors.nil? or self.movement_behaviors.empty?
      behavior_array = self.movement_behaviors
      if @noticed and not self.noticed_behaviors.nil?
#         puts "noticed behavior"
        self.movement_behaviors.first.cancel if not self.movement_behaviors.first.complete? and not self.movement_behaviors.first.executed?
        behavior_array = self.noticed_behaviors
      elsif @alert and not self.alert_behaviors.nil?
#         puts "alert behavior"
        self.movement_behaviors.first.cancel if not self.movement_behaviors.first.complete? and not self.movement_behaviors.first.executed?
        behavior_array = self.alert_behaviors
        #FIXME: now we have all these behaviors to deal with.
        raise "fixme"
      else
#         puts "regular behavior"
        self.noticed_behaviors.first.cancel if not self.noticed_behaviors.nil? and not self.noticed_behaviors.first.complete? and self.noticed_behaviors.first.executed?
      end
      rotate_behaviors if behavior_array.first.complete?
      behavior_array.first.run unless behavior_array.first.executed?
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def walk_right_for(ms)
      behavior = MovementBehavior.create { move_right }
      behavior.at_end { stop_totally }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def walk_left_for(ms)
      behavior = MovementBehavior.create { move_left }
      behavior.at_end { stop_totally }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def look_right_for(ms)
      behavior = MovementBehavior.create { @facing = :right }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def look_left_for(ms)
      behavior = MovementBehavior.create { @facing = :left }
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def walk_toward_player_for(ms)
      behavior = MovementBehavior.create do
        if game_state.player.x > self.x
          move_right
        else
          move_left
        end
      end
      if @recording_noticed_behavior
        behavior.at_end { stop_moving if not @noticed }
      else
        behavior.at_end { stop_moving }
      end
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    private
    def rotate_behaviors
      if @noticed and not self.noticed_behaviors.nil?
        self.noticed_behaviors.push(self.noticed_behaviors.shift)
      else
        self.movement_behaviors.push(self.movement_behaviors.shift)
      end
    end

    private
    def record_behavior(behavior)
      raise "Must be called inside define_movement block" if self.movement_behaviors.nil?
      if @recording_noticed_behavior
        raise "Must be called inside if_noticed block" if self.noticed_behaviors.nil?
        @noticed_behaviors << behavior
      else
        @movement_behaviors << behavior
      end
    end
  end


  class MovementBehavior < Chingu::BasicGameObject
    trait :timer
    attr_accessor :action, :image
    question_accessor :complete
    question_accessor :executed

    def initialize(&block)
      super
      # Note: we have an image accessor to keep things running smoothly with the
      # GameObject stuff, although there is clearly no image. We need to be a
      # BasicGameObject so we can use the Timer trait.
      @action = block
    end

    def at_end(&block)
      @at_end_block = block
    end

    # You can pass :random_period instead of an integer milliseconds and it will
    # choose a time between 0-3 seconds.
    def completed_after(ms)
      raise "Cannot redefine completion block" if @complete_block
      @complete_block = Proc.new do
        time = ms
        time = rand(3.seconds) if ms == :random_period
        @timer_name = "completed_after_#{Time.now.to_i}"
        after(time, :name => @timer_name, :persistent => true) { complete_run }
      end
    end

    def run
      raise "Cannot call run block again: already running" if self.executed?
      @complete_block.call if @complete_block
      @action.call if @action
      self.executed = true
      self.complete = false
    end

    def cancel
      stop_timer(@timer_name) if @timer_name
      complete_run
    end

    private
    def complete_run
      raise "Cannot complete run block: already completed" if self.complete?
      raise "Cannot complete run block: not yet started" unless self.executed?
      @at_end_block.call if @at_end_block
      self.complete = true
      self.executed = false
    end
    
  end # MovementBehavior
end # Leaf
