module Leaf
  module MovementStates
    attr_accessor :movement_states

    def initialize_movement_states
      return unless self.movement_states.nil?
      self.movement_states = []
    end

    def add_movement_state(state)
      initialize_movement_states
      self.movement_states << state unless has_movement_state?(state)
    end

    def remove_movement_state(state)
      initialize_movement_states
      self.movement_states.delete(state)
    end

    def has_movement_state?(state)
      initialize_movement_states
      self.movement_states.include? state
    end
  end # MovementStates


  module MovementBehaviors
    attr_accessor :movement_behaviors

    # Call this and pass a block to begin programming movement behaviors. With
    # no additional sub-blocks, we record the default behavior. You may program
    # behaviors in reaction to specific states by using
    # #record_behavior_for_state or its cousins #if_noticed, #if_alert, etc.
    def define_movement(&block)
      self.movement_behaviors = {:default => []}
      @recording_behavior = :default
      block.call
    end

    # Takes a block within which behavior methods may be called (eg:
    # walk_right_for) that will be executed when we notice the player.
    def if_noticed(&block)
      record_behavior_for_state(:noticed, &block)
    end

    # Takes a block within which behavior methods may be called (eg:
    # walk_right_for) that will be executed when we are alert.
    def if_alert(&block)
      record_behavior_for_state(:alert, &block)
    end

    # Takes a block within which behavior methods may be called (eg:
    # walk_right_for) that will be executed during a certain state (as defined
    # by #movement_states).
    #
    # It's likely easier to use the pre-defined methods for certain states, like
    # #if_noticed and #if_alert.
    def record_behavior_for_state(state, &block)
      @recording_behavior = state
      self.movement_behaviors[state] = []
      block.call
      @recording_behavior = :default
    end

    # Run the next movement behavior.
    #
    # Silently fail if no movements are defined.
    def play_next_movement
      return if self.movement_behaviors.nil?
      state = current_behavior_state
#       puts "current state: #{state}"
      behavior_array = self.movement_behaviors[state]
      cancel_running_behaviors_except_for(state)
      rotate_behaviors(state) if behavior_array.first.complete? or behavior_array.first.does_not_block
      behavior_array.first.run unless behavior_array.first.executed?
    end

    def set_speed_to(speed)
      behavior = MovementBehavior.create { return if @save_old_speed; @save_old_speed = self.speed; self.speed = speed }
      behavior.at_end { self.speed = @save_old_speed if @save_old_speed; @save_old_speed = nil }
      behavior.does_not_block = true
      record_behavior(behavior)
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
      if @recording_behavior == :noticed
        behavior.at_end { stop_moving if not movement_states.include? :noticed }
      else
        behavior.at_end { stop_moving }
      end
      behavior.completed_after(ms)
      record_behavior(behavior)
    end

    private
    def current_behavior_state
      states = [:noticed, :alert, :default]
      states.each do |state|
       return state if has_movement_state?(state) and self.movement_behaviors.has_key? state and not self.movement_behaviors[state].empty?
      end
      :default
    end

    private
    def cancel_running_behaviors_except_for(current_state)
      self.movement_behaviors.each_key do |state|
        next if state == current_state
        next if self.movement_behaviors[state].empty?
        self.movement_behaviors[state].each do |behavior|
          behavior.cancel if behavior.executed? and not behavior.complete?
        end
      end
    end

    private
    def rotate_behaviors(state)
      self.movement_behaviors[state].push(self.movement_behaviors[state].shift)
    end

    private
    def record_behavior(behavior)
      raise "Cannot record behavior: Must be called inside #define_movement block" if self.movement_behaviors.nil?
      state = @recording_behavior
      raise "Cannot record behavior: Must be called inside #record_behavior_for_state(#{state}) (or other appropriate) block" unless self.movement_behaviors.has_key? state
      self.movement_behaviors[state] << behavior
    end
  end


  class MovementBehavior < Chingu::BasicGameObject
    trait :timer
    attr_accessor :action, :image, :does_not_block
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
