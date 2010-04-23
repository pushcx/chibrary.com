require 'test_helper'

class RemoteConnectionTest < ActiveSupport::TestCase
  context 'a remote connection' do
    setup do
      @ssh = mock("ssh connection")
      @sftp = mock("sftp connection")
      @ssh.expects(:sftp).returns(mock(:connect => @sftp))
      Net::SSH.expects(:start).returns(@ssh)
      @rc = RemoteConnection.new
    end

    should 'create connections' do
      # happens in setup, but I want one test just for it
      assert @rc
    end

    should 'tear down ssh and sftp connections on close' do
      @ssh.expects(:close)
      @sftp.expects(:close)
      @rc.close
    end

    should 'send commands to the servever' do
      process = mock("process")
      process.expects(:popen3).with("command")
      @ssh.expects(:process).returns(process)
      @rc.command("command")
    end

    should 'upload files via sftp' do
      @rc.expects(:rand).returns(3)
      handle = mock("handle")
      @sftp.expects(:open_handle).with("tmp/#{Process.pid}-3", "w").yields(handle)
      @sftp.expects(:write).with(handle, "str")
      @sftp.expects(:fsetstat).with(handle, :permissions => 0644)
      @rc.expects(:command).at_least_once
      @rc.upload_file "path/to/filename", "str"
    end
  end
end
