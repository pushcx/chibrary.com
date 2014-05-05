require 'ice_nine'

module IceNine
  module DeepFreeze
    def initiaize
      super
      # shallow freeze; any frozen values already have frozen values
      IceNine.deep_freeze!(self)
    end
  end
end
