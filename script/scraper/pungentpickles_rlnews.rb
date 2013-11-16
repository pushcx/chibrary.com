#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

require 'hpricot'

class ScrapeRLNews < Filer
  def source
    'pungentpickles'
  end

  def acquire
    Dir['pungentpickles.com/rlnews/*.html'].select { |p| p =~ /\/\d+\.html/ }.sort.each do |path|
      doc = Hpricot.parse(open(path))
      date = nil
      (doc/'td').each do |match|
        next unless match.inner_html =~ /COLOR="WHITE"/ or date
        next if match.inner_html =~ /center/ # skip header
        if !date
          date = match.inner_text
        else
          subject = (match/'b').first.inner_text
          yield <<MAIL
From: Roguelike News <rogue@skoardy.demon.co.uk>
Subject: #{subject}
Date: #{date}

#{match.inner_html}
MAIL
          date = nil
        end
      end
    end
  end
end

ScrapeRLNews.new(1, nil).run
