module Leaf

  class Background

    include Rubygame::Sprites::Sprite

    def initialize(width, height)
      @image = Rubygame::Surface.new([width, height])
      @rect = @image.make_rect

      @image.fill([0, 0, 0])
    end

  end # Background


  class Platform
    include Rubygame::Sprites::Sprite

    def initialize(width, height)
      @image = Rubygame::Surface.new([width, height])
      @rect = @image.make_rect

      @image.fill([255, 255, 255])
    end

  end # Platform

end # Leaf
