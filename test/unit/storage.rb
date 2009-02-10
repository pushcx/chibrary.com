require File.dirname(__FILE__) + '/../test_helper'
require 'storage'

class ZipFileTest < Test::Unit::TestCase
  def setup
    FileUtils.cp('test/fixtures/example.zip', '/tmp/test.zip')
  end

  def teardown
    File.unlink('/tmp/test.zip') if File.exists? '/tmp/test.zip'
  end

  def test_string
    archive = Zip::Archive.open '/tmp/test.zip'
    z = archive.fopen('mail1@example.com')
    z.expects(:read).yields("a bunch of text")
    assert_equal "a bunch of text", z.contents
  end

  def test_yaml
    archive = Zip::Archive.open '/tmp/test.zip'
    z = archive.fopen('mail1@example.com')
    z.expects(:read).yields("--- \n:a: :b\n")
    assert_equal({ :a => :b }, z.contents)
  end

  # zipruby was misdesigned to be case-insensitive; bug was reported and author
  # claims to have fixed it. This should watch for it reappearing.
  def test_case
    archive = Zip::Archive.open '/tmp/test.zip'
    archive.add_or_replace_buffer('A', 'uppercase')
    archive.add_or_replace_buffer('a', 'lowercase')
    archive.commit()
    assert_equal 'uppercase', archive.fopen('A') { |f| f.contents }
    assert_equal 'lowercase', archive.fopen('a') { |f| f.contents }
  end
end

class FileChangesTest < Test::Unit::TestCase
  def test_contents
    File.open('/tmp/foo', 'w') do |f|
      f.expects(:seek)
      f.expects(:read).returns("a bunch of text")
      assert_equal "a bunch of text", f.contents
    end
    File.delete('/tmp/foo')
  end

  def test_size
    File.open('/tmp/foo', 'w') do |f|
      f.expects(:seek)
      f.expects(:read).returns("--- \n:a: :b\n")
      assert_equal({ :a => :b }, f.contents)
    end
    File.delete('/tmp/foo')
  end
end

class ZZipTest < Test::Unit::TestCase
  def setup
    FileUtils.cp('test/fixtures/example.zip', '/tmp/test.zip')
  end

  def teardown
    File.unlink('/tmp/test.zip') if File.exists? '/tmp/test.zip'
  end

  def test_has_key?
    z = ZZip.new("/tmp/test.zip")
    assert_equal true,  z.has_key?('mail1@example.com')
    assert_equal true,  z.has_key?('mail2@example.com')
    assert_equal false, z.has_key?('mail3@example.com')
  end

  def test_each
    z = ZZip.new("/tmp/test.zip")
    assert_equal ['mail1@example.com', 'mail2@example.com'], z.collect.sort
  end

  def test_first
    z = ZZip.new("/tmp/test.zip")
    assert_match /mail.@example\.com/, z.first
  end

  def test_lookup
    z = ZZip.new("/tmp/test.zip")
    assert_match /Message body\./, z['mail1@example.com']
    assert_match /A reply without a quote/, z['mail2@example.com']
  end

  def test_assign_add
    z = ZZip.new("/tmp/test.zip")
    z['mail3@example.com'] = "Testing addition."
    assert z.has_key?('mail3@example.com')
    assert_equal "Testing addition.", z['mail3@example.com']
  end

  def test_assign_overwrite
    z = ZZip.new("/tmp/test.zip")
    z['mail1@example.com'] = "Testing overwrite."
    assert z.has_key?('mail1@example.com')
    assert_equal "Testing overwrite.", z['mail1@example.com']
  end

  def test_delete
    z = ZZip.new("/tmp/test.zip")
    z.delete('mail1@example.com')
    assert_equal ['mail2@example.com'], z.collect.sort
  end
end

class ZDirTest < Test::Unit::TestCase
def test_truth ; assert true ; end
  def setup
    FileUtils.cp_r('test/fixtures/example_dir', '/tmp/test')
  end

  def teardown
    FileUtils.rm_rf('/tmp/test') if File.exists? '/tmp/test'
  end


  def test_has_key?
    z = ZDir.new('/tmp/test')
    assert z.has_key?('mail1@example.com')
    assert_equal false, z.has_key?('mail3@example.com')
  end
  
  def test_has_key?_path
    z = ZDir.new('/tmp/test')
    assert z.has_key?('foo/nested@example.com')
  end

  def test_each
    z = ZDir.new("/tmp/test")
    assert_equal ['mail1@example.com', 'mail2@example.com'], z.collect.sort
  end

  def test_each_recurse
    z = ZDir.new("/tmp/test")
    l = []
    z.each(true) {|f| l << f }
    assert_equal ['foo/nested@example.com', 'mail1@example.com', 'mail2@example.com'], l.sort
  end

  def test_first
    z = ZDir.new("/tmp/test")
    assert_match /foo\/nested@example\.com/, z.first
  end

  def test_lookup
    z = ZDir.new("/tmp/test")
    assert_match /Message body\./, z['mail1@example.com']
    assert_match /A reply without a quote/, z['mail2@example.com']
  end

  def test_overwrite_add
    z = ZDir.new("/tmp/test")
    z['mail3@example.com'] = "Testing addition."
    assert z.has_key?('mail3@example.com')
    assert_equal "Testing addition.", z['mail3@example.com']
  end

  def test_assign
    z = ZDir.new("/tmp/test")
    z['mail1@example.com'] = "Testing overwrite."
    assert z.has_key?('mail1@example.com')
    assert_equal "Testing overwrite.", z['mail1@example.com']
  end

  def test_delete
    z = ZDir.new("/tmp/test")
    z.delete('mail1@example.com')
    assert_equal ['mail2@example.com'], z.collect.sort
  end
  
  def test_delete_path
    z = ZDir.new('/tmp/test')
    z.delete('foo/nested@example.com')
    assert_equal [], z['foo'].collect.sort
  end
end
