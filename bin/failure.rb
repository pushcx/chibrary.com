#!/usr/bin/ruby

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'aws'
require 'filer'

class Failure < Filer
  def setup
    @errors = AWS::S3::Bucket.keylist("listlibrary_archive", "filer_failure/")
    puts "#{@errors.size} errors"
  end

  def acquire
    @errors.each do |key|
      error = AWS::S3::S3Object.load_yaml(key)
      puts 
      puts "#{error[:exception]}: #{error[:message]}"
      puts error[:backtrace]
      while 1
        puts
        puts key
        print "Backtrace/Mail/File/Delete/Next/Get: "
        case gets.chomp.downcase[0..0]
        when 'b'
          puts error[:backtrace]
        when 'm'
          puts error[:mail]
        when 'f'
          if yield error[:mail]
            AWS::S3::S3Object.delete key, 'listlibrary_archive'
            break
          end
        when 'd'
          AWS::S3::S3Object.delete key, 'listlibrary_archive'
          break
        when 'g'
          File.open(key, 'w') { |f| f.puts error.to_yaml }
        when 'n'
          break
        end
      end
    end
  end
end

Failure.new.run if __FILE__ == $0
