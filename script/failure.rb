#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/boot'
require "#{RAILS_ROOT}/config/environment"

require 'tempfile'

class Failure < Filer
  def setup
    @errors = AWS::S3::Bucket.keylist("listlibrary_archive", "filer_failure/")
    @ignores = []
    puts "#{@errors.size} errors"
  end

  def delete_error key
    AWS::S3::S3Object.delete key, 'listlibrary_archive'
  end

  def acquire
    @errors.each do |key|
      error = AWS::S3::S3Object.load_yaml(key)

      if @ignores.include? error[:message]
        delete_error key
        next
      end

      if error[:exception] == 'RuntimeError' and error[:message] =~ /^overwrite attempted/
        print "#{key} is an overwrite, "
        attempt = Message.new error[:mail], 'failure', call_number
        begin
          current = Message.new attempt.key
        rescue AWS::S3::NoSuchKey
          # spurious overwrite error
          yield attempt.message, nil
          delete_error key
          next
        end
        if attempt.message.strip != current.message.strip
          # code to open a vimdiff
          #c_tf = Tempfile.open('current')
          #c_tf.puts current.message
          #c_tf.close
          #a_tf = Tempfile.open('attempt')
          #a_tf.puts attempt.message
          #a_tf.close
          #`xterm -e vimdiff #{c_tf.path} #{a_tf.path}`
          #c_tf.unlink
          #a_tf.unlink
          yield attempt.message, :dont
          puts "filed as new message"
        else
          puts "deleted the dupe"
        end
        delete_error key
        next
      end

      puts 
      puts "#{error[:exception]}: #{error[:message]}"
      puts error[:backtrace] unless error[:message] =~ /^overwrite attempted/
      while 1
        puts
        puts key
        print "File/Backtrace/Mail/Delete/Ignore/Next/Get: "
        case gets.chomp.downcase[0..0]
        when 'b'
          puts error[:backtrace]
        when 'm'
          puts error[:mail]
        when 'd'
          delete_error key
          break
        when 'i'
          @ignores << error[:message]
          delete_error key
          break
        when 'g'
          File.open(key.split('/').last, 'w') { |f| f.puts error.to_yaml }
        when 'n'
          break
        else # 'f'
          if yield error[:mail]
            delete_error key
            break
          end
        end
      end
    end
  end
end

Failure.new.run if __FILE__ == $0
