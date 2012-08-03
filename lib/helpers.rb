module Leaf
  module Hidable
    attr_accessor :hidden
    def update
      self.hide! if @hidden
      self.show! if not @hidden
      super
    end
  end

  module Standable
  end

  module Unpassable
  end

  module BlocksVision
  end

  module Climbable
  end

end # Leaf
