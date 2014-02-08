class InvalidSlug < RuntimeError ; end

class NullList
  attr_reader :slug, :name, :description, :homepage, :footer

  def initialize
    @slug = '_null_list'
    @name = 'NillList'
  end
end

class List
  attr_reader :slug, :name, :description, :homepage, :footer

  def initialize slug, name=nil, description=nil, homepage=nil, footer=nil
    raise InvalidSlug, "Invalid list slug '#{slug}'" unless slug =~ /^[a-z0-9\-]+$/ and slug.length <= 20
    @slug = slug
    @name = name
    @description = description
    @homepage = homepage
    @footer = footer
  end

  def == other
    (
      slug == other.slug and
      name == other.name and
      description == other.description and
      homepage == other.homepage
    )
  end
end
