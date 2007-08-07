#!/usr/bin/ruby

require 'net/pop'
require 'message'
require 'aws'
require 'mail'

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

def call_number server, pid, sequence
  # call numbers are 48 binary digits. First 8 are 0 for future
  # expansion. Next 4 are server id. Next 16 # are process id.
  # Last 20 are an incremeting sequence ID.
  ("%04b%016b%020b" % [0, pid, sequence]).to_i(2).to_base_64
end

if __FILE__ == $0

  server = CachedHash.new("servers")[`hostname`].to_i
  sequence = CachedHash.new("sequences")["#{server}/#{Process.pid}"].to_i

  pop = Net::POP3.new(MAIL_SERVER, MAIL_POP3_PORT)
  pop.open_timeout = 300
  #pop.set_debug_output $stderr
  pop.start(MAIL_USER, MAIL_PASSWORD)
  puts "#{pop.n_mails} to process:"
  begin
    pop.delete_all do |mail|
      next if mail.length >= (256 * 1024)
      message = Message.new(mail.pop, call_number(server, Process.pid, sequence))
      begin
        message.store
        puts "#{mail.number} #{message.filename}"
      rescue Exception => e
        puts "#{mail.number} failed to store: #{e.message}; failure stored as #{message.call_number}"
        AWS::S3::S3Object.store(
          "_listlibrary_failed/#{message.call_number}",
          e.message + "\n" + e.backtrace.join("\n") + "\n\n" + message.message,
          'listlibrary_archive',
          :content_type => "text/plain"
        )
      ensure
        sequence += 1
      end
    end
  ensure
    pop.finish
    CachedHash.new("sequences")["#{server}/#{Process.pid}"] = sequence
  end

end
