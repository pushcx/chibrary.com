require_relative '../../rspec'
require_relative '../../../lib/remote_connection'

describe RemoteConnection do
  let(:sftp) { double("sftp connection") }
  let(:ssh)  { double("ssh connection", sftp: double('connector', connect: sftp)) }
  let(:rc)   { RemoteConnection.new }

  before do
    Net::SSH.stub(:start).and_return(ssh)
  end

  it 'tear down ssh and sftp connections on close' do
    ssh.should_receive(:close)
    sftp.should_receive(:close)
    rc.close
  end

  it 'send commands to the server' do
    process = double("process")
    process.should_receive(:popen3).with("command")
    ssh.should_receive(:process).and_return(process)
    rc.command("command")
  end

  it 'upload files via sftp' do
    rc.should_receive(:rand).and_return(3)
    handle = double("handle")
    sftp.should_receive(:open_handle).with("tmp/#{Process.pid}-3", "w").and_yield(handle)
    sftp.should_receive(:write).with(handle, "str")
    sftp.should_receive(:fsetstat).with(handle, :permissions => 0644)
    rc.should_receive(:command).at_least(:once)
    rc.upload_file "path/to/filename", "str"
  end
end
