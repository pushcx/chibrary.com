require 'forwardable'

require_relative '../value/call_number'
require_relative '../value/email'
require_relative '../value/slug'
require_relative '../value/sym'

module Chibrary

class Message
  attr_accessor :email, :call_number, :slug, :source, :overlay

  extend Forwardable
  def_delegators :@email, :direct_quotes, :likely_thread_creation_from?, :lines_matching, :quotes

  def initialize email, call_number, slug, source, overlay={}
    @email = email
    @call_number = CallNumber.new(call_number)
    @slug = Slug.new(slug)
    @source = source
    @overlay = overlay
    generate_message_id unless message_id.valid?
  end

  def sym
    Sym.new(slug, date.year, date.month)
  end

  def generate_message_id
    self.message_id = MessageId.generate_for(call_number)
  end

  [:from, :references, :no_archive?, :body].each do |field|
    define_method(field) do
      overlay.fetch(field, email.public_send(field))
    end
  end
  [:message_id, :subject, :date, :from, :references, :no_archive, :body].each do |field|
    define_method("#{field}=") do |value|
      overlay[field] = value
    end
  end
  def message_id
    MessageId.new(overlay.fetch(:message_id, email.message_id))
  end
  def subject
    Subject.new(overlay.fetch(:subject, email.subject))
  end
  def n_subject
    subject.normalized
  end
  def date
    Time.rfc2822(overlay.fetch(:date, email.date.rfc2822))
  end

  def blurb
    body.split("\n").select { |l| not (l.chomp.empty? or l =~ /^ *>|@|:$/) }.join("\n")[0..149]
  end

  def to_s
    "<Message(#{call_number}) #{message_id}>"
  end

  def likely_split_thread?
    subject.reply? or body_quotes?
  end

  # this is kinda dumb about quotes... see compress_quotes in web/
  def body_quotes?
    body =~ /^[>\|] .+/
  end

  def == o
    o.email == email and o.slug == slug and o.source == source and o.call_number == call_number and o.message_id == message_id
  end

  def self.from_string str, call_number, slug, source='string', overlay={}
    Message.new Email.new(str), call_number, slug, source, overlay
  end

  def self.from_message m
    Message.new m.email, m.call_number, m.slug, m.source, m.overlay
  end
end

end # Chibrary
