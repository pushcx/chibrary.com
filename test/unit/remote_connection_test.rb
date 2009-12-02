require File.dirname(__FILE__) + '/../test_helper'
require 'remote_connection'

class RemoteConnectionTest < Test::Unit::TestCase
  def setup
    @ssh = mock("ssh connection")
    @sftp = mock("sftp connection")
    @ssh.expects(:sftp).returns(mock(:connect => @sftp))
    Net::SSH.expects(:start).returns(@ssh)
    @rc = RemoteConnection.new
  end

  def test_initialize
    # happens in setup, but I want one test just for it
    assert @rc
  end

  def test_close
    @ssh.expects(:close)
    @sftp.expects(:close)
    @rc.close
  end

  def test_command
    process = mock("process")
    process.expects(:popen3).with("command")
    @ssh.expects(:process).returns(process)
    @rc.command("command")
  end

  def test_upload_file
    @rc.expects(:rand).returns(3)
    handle = mock("handle")
    @sftp.expects(:open_handle).with("tmp/#{Process.pid}-3", "w").yields(handle)
    @sftp.expects(:write).with(handle, "str")
    @sftp.expects(:fsetstat).with(handle, :permissions => 0644)
    @rc.expects(:command).at_least_once
    @rc.upload_file "path/to/filename", "str"
  end
end
