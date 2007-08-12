#!/usr/bin/ruby

require 'time'
require 'md5'
require 'aws'

class Message
  attr_reader   :headers, :message, :call_number, :source
  attr_reader   :from, :date, :subject, :in_reply_to, :reply_to
  attr_accessor :addresses, :overwrite, :S3Object

  def initialize message, source=nil, call_number=nil
    # call_number is loaded from message when possible
    @S3Object = AWS::S3::S3Object
    @addresses = CachedHash.new "list_address"

    @source = source
    @call_number = call_number
    if message.match "\n" # initialized with a message
      @message = message
    else                  # initialize with a url
      @overwrite = true
      o = @S3Object.find(message, 'listlibrary_archive')
      @message = o.value
      @call_number ||= o.metadata['call_number']
      @source ||= o.metadata['source']
    end
    raise "call_number #{call_number} invalid string" unless call_number.instance_of? String and call_number.length == 8
    populate_headers
  end

  def populate_headers
    @headers     = /(.*?)\n\r?\n/m.match(message)[1]

    @date        = /^Date:\s(.*)$/.match(headers)
    begin
      @date      = date[1].chomp
      @date      = Time.rfc2822(@date).utc
    rescue
      # It's ugly to assume odd-formated dates are local time, but
      # servers will generally be running in UTC. If you can't properly
      # format an rfc2822 date, you're lucky to get anything I give you.
      @date      = Time.parse(@date).utc rescue Time.now.utc
    end

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
    [ /^X-Mailing-List:\s.*/,
      /^To:\s.*/, /^C[cC]:\s.*/,
      /^B[cC][cC]:\s.*/,
      /^Reply-[Tt]o:\s.*/,
      /^List-[Pp]ost:\s.*/,
      /^Mail-[Ff]ollowup-[Tt]o:\s.*/,
      /Mail-[Rr]eply-[Tt]o:\s.*/
    ].each do |regexp|
      matches = regexp.match(headers)
      break unless matches.nil?
    end
    return "_listlibrary_no_list" if matches.nil?

    slug = nil
    matches[0].chomp.split(/[^\w@\.\-_]/).select { |s| s =~ /@/ }.each do |address|
      slug = @addresses[address]
      break unless slug.nil?
    end

    slug ||= "_listlibrary_no_list"
  end

  def generated_id
    "#{call_number}@generated-message-id.listlibrary.net"
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

  def filename
    "list/#{mailing_list}/message/#{date.year}/%02d/" % date.month + message_id
  end

  def store
    unless @overwrite
      raise "overwrite attempted for listlibrary_archive #{filename}" if @S3Object.exists?(filename, "listlibrary_archive")
    end
    @S3Object.store(filename, message, "listlibrary_archive", {
      :content_type             => "text/plain",
      :'x-amz-meta-from'        => from,
      :'x-amz-meta-subject'     => subject,
      :'x-amz-meta-in_reply_to' => in_reply_to,
      :'x-amz-meta-date'        => date,
      :'x-amz-meta-source'      => @source,
      :'x-amz-meta-call_number' => call_number
    })
    self
  end
end
