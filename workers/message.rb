#!/usr/bin/ruby

require 'time'
require 'md5'
require 'aws'

class Integer
  def to_base_64
    chars = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a + ['_', '-']
    str = ""
    current = self

    while current != 0
      str = chars[current % 64].to_s + str
      current = current / 64
    end
    raise "Unexpectedly large int converted" if str.length > 8
    ("%8s" % str).tr(' ', '0')
  end
end

class Message
  attr_reader   :headers, :message
  attr_reader   :from, :date, :subject, :in_reply_to, :reply_to
  attr_accessor :addresses, :overwrite, :S3Object

  def initialize message, sequence=nil
    # sequence is loaded from message when possible
    @S3Object = AWS::S3::S3Object
    @addresses = CachedHash.new "mailing_list_addresses"

    if message.match "\n" # initialized with a message
      @message = message
      @sequence = sequence
      raise "sequence #{sequence} out of bounds" if sequence < 0 or sequence > 2 ** 28
    else                  # initialize with a url
      o = @S3Object.find(message, 'listlibrary_storage').value
      @message = o.value
      @sequence = o.metadata['public_id']
      raise "sequence #{sequence} given when none should have been" unless sequence.nil?
    end
    populate_headers
  end

  def populate_headers
    @headers     = /(.*?)\n\r?\n/m.match(message)[1]

    date_line    = /^Date:\s(.*)$/.match(headers)[1].chomp
    @date        = Time.rfc2822(date_line).utc rescue Time.parse(date_line).utc

    begin
      @subject   = /^Subject:\s*(.*)/.match(headers).captures.shift
    rescue 
      add_header "Subject: "
      @subject   = ''
    end
    @from        = /^From:\s*(.*)/.match(headers).captures.shift.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.shift
    @reply_to    = /^Reply-[Tt]o:\s*(.*)/.match(headers).captures.shift.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.shift if headers.match(/^Reply-[Tt]o/)

    begin
      @in_reply_to = /^In-[Rr]eply-[Tt]o:\s*<?(.*)>?/.match(headers).captures.shift
    rescue
      @in_reply_to = nil
      # assume last reference is the parent and use it
      if references = /^References:\s*(.*)/.match(headers)
        @in_reply_to = references.captures.shift.split(/\s+/).last.match(/<?([^>]+)>?/).captures.shift
      end
    end
  end

  def mailing_list
    matches = nil
    [/^X-Mailing-List:\s.*/, /^To:\s.*/, /^C[cC]:\s.*/, /^Reply-[Tt]o:\s.*/].each do |regexp|
      matches = regexp.match(headers)
      break unless matches.nil?
    end
    return nil if matches.nil?

    slug = nil
    matches[0].chomp.split(/[^\w@\.\-]/).select { |s| s =~ /@/ }.each do |address|
      slug = @addresses[address]
      break unless slug.nil?
    end

    slug
  end

  def generated_id
    "#{public_id}@generated-message-id.listlibrary.net"
  end

  def add_header(header)
    name = header.match(/^(.+?):\s/).captures.shift
    new_headers = "#{header.chomp}\n"
    new_headers += "X-ListLibrary-Added-Header: #{name}\n" unless name.match(/^X-ListLibrary-/)
    @headers = new_headers + headers
    @message = new_headers + message
  end

  def message_id
    begin
      /^Message-[Ii][dD]:\s*<?(.*)>/.match(headers)[1].chomp
    rescue
      add_header "Message-Id: <#{generated_id}>"
      message_id
    end
  end

  def bucket
    mailing_list ? 'listlibrary_storage' : 'listlibrary_no_mailing_list'
  end

  def filename
    ( mailing_list ? "#{mailing_list}/" : "" ) + "#{date.year}/%02d/" % date.month + message_id
  end

  def public_id
    # Public IDs are 48 binary digits. First 4 are server id. Next 16
    # are process id. Last 28 are an incremeting sequence ID. The caller
    # is responsible for unique sequence IDs at instantiation.

    # `hostname`.chomp TODO allow multiple hosts, replace 0 on next line
    ("%04b%016b%020b" % [0, Process.pid, @sequence]).to_i(2).to_base_64
  end

  def store
    unless @overwrite
      raise "overwrite attempted for #{bucket} #{filename}" if @S3Object.exists?(filename, bucket)
    end
    @S3Object.store(filename, message, bucket, {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => from,
      :'x-amz-meta-subject'     => subject,
      :'x-amz-meta-in_reply_to' => in_reply_to,
      :'x-amz-meta-date'        => date,
      :'x-amz-meta-public_id'   => public_id
    })
    self
  end
end
