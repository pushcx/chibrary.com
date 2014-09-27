require_relative '../value/slug'

module Chibrary

class NullList
  attr_reader :slug, :name, :description, :homepage, :footer

  def initialize
    @slug = '_null_list'
    @name = 'NillList'
  end

  def null? ; true ; end
end

class List
  attr_reader :slug, :name, :description, :homepage, :footer

  def initialize slug, name=nil, description=nil, homepage=nil, footer=nil
    @slug = Slug.new(slug)
    @name = name
    @description = description
    @homepage = homepage
    @footer = footer
  end

  def title_name
    name || slug
  end

  def == other
    (
      slug == other.slug and
      name == other.name and
      description == other.description and
      homepage == other.homepage
    )
  end

  def null? ; false ; end
end

end # Chibrary
