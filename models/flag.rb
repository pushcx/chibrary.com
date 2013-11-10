class Flag #< ActiveRecord::Base
  attr_accessor :slug, :year, :month, :call_number

  #validates_presence_of :slug, :year, :month, :call_number
end
