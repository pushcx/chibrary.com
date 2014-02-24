require 'fileutils'
require 'yaml'
require 'riak'
require 'zipruby'
require 'active_support/core_ext/string'
require_relative 'string_'

class NotFound < RuntimeError ; end

def de_yamlize content
  # don't deserialize to Message class, which little-resembles the Message
  # class from when these objects were yamlized
  content = content.to_utf8 'ascii-8bit'
  content.gsub!(/[^\n]/, "")
  content.gsub!(/^--- !ruby\/object:Message *\n/, "--- \n") if content[0..4] == '--- !'
  content.gsub!(/^subject: .*\n/, '')
  content = YAML::load(content) if content[0..3] == '--- '
  content
rescue Psych::SyntaxError # fuck everything about loading those subjects that YAML has smashed
  YAML::load(content.match(/^message: .*/m).to_s)
end

class Zip::File
  def contents
    de_yamlize raw_contents
  end
  def raw_contents
    #output = ''
    read# { |chunk| output << chunk }
  end
end

class File
  def contents
    de_yamlize raw_contents
  end
  def raw_contents
    seek(0)
    read
  end

  def size
    read.length
  end
end

class ZZip
  include Enumerable

  def initialize path
    @path = path
  end

  def has_key? path
    zip { |z| z.locate_name(path) != -1 }
  end

  def each(recurse=false)
    # recurse is unused, but listed to match ZDir
    files = []
    zip { |z| z.each { |entry| files << entry.name unless entry.name.ends_with? '/' } }
    files.sort!
    files.each { |f| yield f }
  end

  def first
    each { |path| return path }
    nil
  end

  def raw path
    return self if path.blank?
    # zip files cannot be nested, don't do ZDir#[]'s check for .zip
    zip { |z| z.fopen(path) { |f| f.raw_contents } }
  rescue Zip::Error
    raise NotFound, File.join(@path, path)
  end

  def [] path
    return self if path.blank?
    # zip files cannot be nested, don't do ZDir#[]'s check for .zip
    zip { |z| z.fopen(path) { |f| f.contents } }
  rescue Zip::Error
    raise NotFound, File.join(@path, path)
  end

  def []= path, value
    value = value.to_yaml unless value.is_a? String
    zip { |z| z.add_or_replace_buffer(path, value) }
  end

  def delete path
    zip do |z|
      if (index = z.locate_name(path)) != -1
        z.fdelete(index)
      end
    end
  end

  private
  def zip
    zip = Zip::Archive.open(@path)
    yield zip
  ensure
    zip.close
  end
end 

class ZDir
  include Enumerable

  def initialize path='.'
    @path = path
  end

  def has_key? path
    return self[path.split('/').first].has_key?(path.split('/')[1..-1].join('/')) if path =~ /\//
      
    [
      [@path, path].join('/'),
      [@path, "#{path}.zip"].join('/'),
      [@path, "#{path}.tcb"].join('/'),
    ].any? { |f| File.exists? f }
  rescue NotFound, File.join(@path, path)
    false
  end

  def each(recurse=false)
    Dir.entries(@path).sort.each do |path|
      next if %w{. ..}.include? path
      yield path if File.file? File.join(@path, path) and not path =~ /\.zip$/
      if File.directory? File.join(@path, path)
        ZDir.new([@path, path].join('/')).each(recurse) { |p| yield File.join(path, p) } if recurse
      elsif path =~ /\.zip$/
        ZZip.new([@path, path].join('/')).each(recurse) { |p| yield File.join(path.gsub('.zip', ''), p) } if recurse
      end
    end
  end

  def collect(recurse=false)
    l = []
    each(recurse) { |path| l << path }
    l
  end

  def first # find first file
    each(true) do |path|
      object = self[path]
      return path unless object.is_a? ZDir or object.is_a? ZZip
    end
    nil
  end

  def raw path
    full_path = File.join([@path, path])
    if !File.exists? full_path
      dirs = full_path.split('/')
      full_path = dirs.shift
      while dir = dirs.shift do
        full_path += "/#{dir}"
        zip_path = full_path + ".zip"
        return ZZip.new(zip_path).raw(dirs.join('/')) if File.exists? zip_path
      end
    end

    raise NotFound, full_path unless File.exists? full_path

    return ZDir.new(full_path)                if File.directory? full_path
    return File.open(full_path, 'r').raw_contents if File.file? full_path

    raise "ZDir(#{@path}) doesn't know what to do with [#{path}]"
  end

  def [] path
    full_path = File.join([@path, path])
    if !File.exists? full_path
      dirs = full_path.split('/')
      full_path = dirs.shift
      while dir = dirs.shift do
        full_path += "/#{dir}"
        zip_path = full_path + ".zip"
        return ZZip.new(zip_path)[dirs.join('/')] if File.exists? zip_path
      end
    end

    raise NotFound, full_path unless File.exists? full_path

    return ZDir.new(full_path)                if File.directory? full_path
    return File.open(full_path, 'r').contents if File.file? full_path

    raise "ZDir(#{@path}) doesn't know what to do with [#{path}]"
  end

  def []= path, value
    dir = "#{@path}/#{path}".split('/')[0..-2].join('/')
    FileUtils.mkdir_p(dir) unless File.exists? "#{dir}.zip" or File.exists? "#{dir}.tcb"

    # recurse into zips
    return self[path.split('/').first][path.split('/')[1..-1].join('/')] = value if path =~ /\//
    if value.is_a? ZDir
      FileUtils.mkdir_p([@path, path].join('/'))
    elsif value.is_a? ZZip or value.is_a? String
      raise "Bug 2537 has recurred" if [@path, path].join('/').starts_with? 'chibrary_archive/list/thread'
      File.open([@path, path].join('/'), 'w') do |f|
        f.write(value.to_s.chomp)
      end
    else
      self[path] = value.to_yaml.to_s
    end
  end

  def delete path
    return self[path.split('/').first].delete(path.split('/')[1..-1].join('/')) if path =~ /\//

    FileUtils.rm_rf([@path, path].join('/')) rescue nil
  end
end

$archive    = ZDir.new('archive')
$cachedhash = ZDir.new('cachedhash')
