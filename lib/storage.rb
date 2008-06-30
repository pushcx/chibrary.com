require 'rubygems'
require 'fileutils'
require 'yaml'
require 'zipruby'

class NotFound < RuntimeError ; end

class Zip::File
  def contents
    output = ''
    read { |chunk| output << chunk }
    return YAML::load(output) if output =~ /^--- /
    return output
  end
end

class File
  def contents
    seek(0)
    output = read
    return YAML::load(output) if output =~ /^--- /
    return output
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

  def each
    zip { |z| z.each { |entry| yield entry.name } }
  end

  def first
    each { |path| return path }
    nil
  end

  def [] path
    # zip files cannot be nested, don't do ZDir#[]'s check for .zip
    zip { |z| z.fopen(path) { |f| f.contents } }
  rescue Zip::Error
    raise NotFound.join(@path, path)
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
      
    File.exists? [@path, path].join('/') or File.exists? [@path, "#{path}.zip"].join('/')
  rescue NotFound, File.join(@path, path)
    false
  end

  def each(recurse=false)
    Dir.entries(@path).each do |path|
      next if %w{. ..}.include? path
      yield path
      if File.directory? File.join(@path, path)
        ZDir.new([@path, path].join('/')).each(recurse) { |p| yield File.join(path, p) } if recurse
      elsif path =~ /\.zip$/
        ZZip.new([@path, path].join('/')).each { |p| yield File.join(path, p) } if recurse
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

  def [] path
    return self[path.split('/').first][File.join(path.split('/')[1..-1])] if path =~ /\//
    path = "#{path}.zip" if !File.exists?(File.join(@path, path)) and path !~ /\.zip$/
    path = [@path, path].join('/')
    raise NotFound, File.join(@path, path) unless File.exists? path

    return ZZip.new(path)                if path =~ /\.zip$/
    return ZDir.new(path)                if File.directory? path
    return File.open(path, 'r').contents if File.file? path

    raise "ZDir(#{@path}) doesn't know what to do with [#{path}]"
  end

  def []= path, value
    dir = "#{@path}/#{path}".split('/')[0..-2].join('/')
    FileUtils.mkdir_p(dir) unless File.exists? "#{dir}.zip"

    # recurse into zips
    return self[path.split('/').first][path.split('/')[1..-1].join('/')] = value if path =~ /\//
    if value.is_a? ZDir
      FileUtils.mkdir_p([@path, path].join('/'))
    elsif value.is_a? ZZip or value.is_a? String
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

$archive    = ZDir.new('listlibrary_archive')
$cachedhash = ZDir.new('listlibrary_cachedhash')
