class GenericController < ApplicationController
  caches_page :about, :homepage, :search

  def about
  end

  def homepage
    @lists = []
    $archive['list'].each do |slug|
      @lists << List.new(slug) if $archive.has_key? "list/#{slug}/thread" and not slug =~ /^_/
    end

    @snippets = []
    $archive['snippet/homepage'].each_with_index { |key, i| @snippets << $archive["snippet/homepage/#{key}"] ; break if i >= 30 }
  end

  def search
  end
end
