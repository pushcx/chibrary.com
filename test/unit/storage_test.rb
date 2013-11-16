require 'test_helper'

class ZipFileTest < ActiveSupport::TestCase
  context 'a zip file' do
    setup do
      FileUtils.cp('test/fixture/example.zip', '/tmp/test.zip')
    end

    teardown do
      File.unlink('/tmp/test.zip') if File.exists? '/tmp/test.zip'
    end

    should 'store strings' do
      archive = Zip::Archive.open '/tmp/test.zip'
      z = archive.fopen('mail1@example.com')
      z.expects(:read).yields("a bunch of text")
      assert_equal "a bunch of text", z.contents
    end

    should 'store yaml for objects' do
      archive = Zip::Archive.open '/tmp/test.zip'
      z = archive.fopen('mail1@example.com')
      z.expects(:read).yields("--- \n:a: :b\n")
      assert_equal({ :a => :b }, z.contents)
    end

    # zipruby was misdesigned to be case-insensitive; bug was reported and author
    # claims to have fixed it. This should watch for it reappearing.
    should 'not let ZipRuby bug smash case' do
      archive = Zip::Archive.open '/tmp/test.zip'
      archive.add_or_replace_buffer('A', 'uppercase')
      archive.add_or_replace_buffer('a', 'lowercase')
      archive.commit()
      assert_equal 'uppercase', archive.fopen('A') { |f| f.contents }
      assert_equal 'lowercase', archive.fopen('a') { |f| f.contents }
    end

  end
end

class FileChangesTest < ActiveSupport::TestCase
  should 'write to files' do
    File.open('/tmp/foo', 'w') do |f|
      f.expects(:seek)
      f.expects(:read).returns("a bunch of text")
      assert_equal "a bunch of text", f.contents
    end
    File.delete('/tmp/foo')
  end

  should 'report file sizes' do
    File.open('/tmp/foo', 'w') do |f|
      f.expects(:seek)
      f.expects(:read).returns("--- \n:a: :b\n")
      assert_equal({ :a => :b }, f.contents)
    end
    File.delete('/tmp/foo')
  end
end

class ZZipTest < ActiveSupport::TestCase
  context 'a zip file' do
    setup do 
      FileUtils.cp('test/fixture/example.zip', '/tmp/test.zip')
      @z = ZZip.new("/tmp/test.zip")
    end

    teardown do
      File.unlink('/tmp/test.zip') if File.exists? '/tmp/test.zip'
    end

    should 'find keys that exist' do
      assert_equal true,  @z.has_key?('mail1@example.com')
      assert_equal true,  @z.has_key?('mail2@example.com')
    end

    should 'not find non-existent keys' do
      assert_equal false, @z.has_key?('mail3@example.com')
    end

    should 'iterate over keys with each' do
      assert_equal ['mail1@example.com', 'mail2@example.com'], @z.collect.sort
    end

    should 'return its first key' do
      assert_match /mail.@example\.com/, @z.first
    end

    should 'load content successfully' do
      assert_match /Message body\./, @z['mail1@example.com']
      assert_match /A reply without a quote/, @z['mail2@example.com']
    end

    should 'add content' do
      @z['mail3@example.com'] = "Testing addition."
      assert @z.has_key?('mail3@example.com')
      assert_equal "Testing addition.", @z['mail3@example.com']
    end

    should 'overwrite content' do
      @z['mail1@example.com'] = "Testing overwrite."
      assert @z.has_key?('mail1@example.com')
      assert_equal "Testing overwrite.", @z['mail1@example.com']
    end

    should 'delete content' do
      @z.delete('mail1@example.com')
      assert_equal ['mail2@example.com'], @z.collect.sort
    end

  end
end

class ZDirTest < ActiveSupport::TestCase
  context 'a zdir' do
    setup do
      FileUtils.cp_r('test/fixture/example_dir', '/tmp/test')
      @z = ZDir.new('/tmp/test')
    end

    teardown do
      FileUtils.rm_rf('/tmp/test') if File.exists? '/tmp/test'
    end

    should "RENAME ME: test has key?" do
      assert @z.has_key?('mail1@example.com')
      assert_equal false, @z.has_key?('mail3@example.com')
    end
    
    should "RENAME ME: test has key? path" do
      assert @z.has_key?('foo/nested@example.com')
    end

    should "RENAME ME: test each" do
      assert_equal ['foo', 'mail1@example.com', 'mail2@example.com'], @z.collect.sort
    end

    should "RENAME ME: test each recurse" do
      l = []
      @z.each(true) {|f| l << f }
      assert_equal ['foo', 'foo/nested@example.com', 'mail1@example.com', 'mail2@example.com'], l.sort
    end

    should "RENAME ME: test first" do
      assert_match /foo\/nested@example\.com/, @z.first
    end

    should "RENAME ME: test lookup" do
      assert_match /Message body\./, @z['mail1@example.com']
      assert_match /A reply without a quote/, @z['mail2@example.com']
    end

    should "RENAME ME: test overwrite add" do
      @z['mail3@example.com'] = "Testing addition."
      assert @z.has_key?('mail3@example.com')
      assert_equal "Testing addition.", @z['mail3@example.com']
    end

    should "RENAME ME: test assign" do
      @z['mail1@example.com'] = "Testing overwrite."
      assert @z.has_key?('mail1@example.com')
      assert_equal "Testing overwrite.", @z['mail1@example.com']
    end

    should "RENAME ME: test delete" do
      @z.delete('mail1@example.com')
      assert_equal ['foo', 'mail2@example.com'], @z.collect.sort
    end
    
    should "RENAME ME: test delete path" do
      @z.delete('foo/nested@example.com')
      assert_equal [], @z['foo'].collect.sort
    end

  end
end

# Uses the Tokyo Cabinet B-Tree backend
class CabinetTest < ActiveSupport::TestCase
  context "creating a cabinet" do
    setup do
      @path = '/tmp/test.tcb'
      File.unlink @path if File.exists? @path
    end

    teardown do
      File.unlink @path if File.exists? @path
    end

    should "create a file" do
      assert !File.exists?(@path)
      c = Cabinet.new @path
      c.has_key? 'foo' # have to interact for it to be created
      assert File.exists?(@path)
    end
  end

  context "working with a cabinet" do
    setup do
      @path = "/tmp/test.tcb"
      FileUtils.cp 'test/fixture/example.tcb', @path
      @cabinet = Cabinet.new @path
    end

    teardown do
      @cabinet.close
      File.unlink @path if File.exists? @path
    end

    should "have a key that exists" do
      assert @cabinet.has_key? 'mail1@example.com'
    end

    should "not have a key that doesn't exists" do
      assert !@cabinet.has_key?('nonexistent')
    end

    should "iterate over keys with each" do
      assert_equal ['mail1@example.com', 'mail2@example.com'], @cabinet.collect
    end

    should "return its first key" do
      assert_equal 'mail1@example.com', @cabinet.first
    end

    should "return contents" do
      assert_match /Message body\./, @cabinet['mail1@example.com']
      assert_match /A reply without a quote/, @cabinet['mail2@example.com']
    end

    should "raise NotFound" do
      assert_raises NotFound do
        @cabinet['nonexistent']
      end
    end

    should "assign new content" do
      @cabinet['mail3@example.com'] = "Testing addition."
      assert @cabinet.has_key? 'mail3@example.com'
      assert_equal "Testing addition.", @cabinet['mail3@example.com']
    end

    should "assign to overwrite" do
      assert @cabinet.has_key? 'mail1@example.com'
      @cabinet['mail1@example.com'] = "Testing overwrite."
      assert_equal "Testing overwrite.", @cabinet['mail1@example.com']
    end

    should "delete files" do
      assert @cabinet.has_key? 'mail1@example.com'
      @cabinet.delete 'mail1@example.com'
      assert !@cabinet.has_key?('mail1@example.com')
    end

    should "delete idempotently" do
      assert !@cabinet.has_key?('nonexistent')
      @cabinet.delete 'nonexistent'
      assert !@cabinet.has_key?('nonexistent')
    end
  end
end
