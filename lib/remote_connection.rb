require 'net/sftp'
require 'net/ssh'

class Net::SFTP::Session
  def exists? filename
    self.open!(filename) and return true
  rescue Net::SFTP::Exception => e
    return false if e.code == Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE
    raise
  end
end

class RemoteConnection
  def initialize
    @ssh = Net::SSH.start(
      "listlibrary.net",
      "listlibrary", {
        :keys => [File.join(File.dirname(__FILE__), "listlibrary_id_dsa")],
        :compression => 'zlib',
        :compression_level => 9,
        :paranoid => :very,
      }
    )
    @sftp = @ssh.sftp.connect
  end

  def close
    @ssh.close
    @sftp.close
  end

  def command cmd
    @ssh.process.popen3(cmd)
  end

  def upload_file filename, contents
    tmpname = "tmp/#{Process.pid}-#{rand(1000000)}"
    dirs = filename.split('/')
    filename = dirs.pop
    path = dirs.join('/')

    @sftp.open_handle(tmpname, "w") do |handle|
      @sftp.write(handle, contents)
      @sftp.fsetstat(handle, :permissions => 0644)
    end
    command("/bin/mkdir -p /home/listlibrary/listlibrary.net/#{path}")
    command("/bin/mv /home/listlibrary/#{tmpname} /home/listlibrary/listlibrary.net/#{path}/#{filename}")
  end

  def remove filename
    return if filename.empty?
    @sftp.remove! "/home/listlibrary/#{filename}"
  rescue Net::SFTP::Exception => e
    raise unless e.code == Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE
  end

  def rmdir dir
    return unless @sftp.exists? dir
    # loop and remove files
    @sftp.dir.foreach("/home/listlibrary/#{dir}") { |f|
      next if %w{. ..}.include? f.name
      remove "#{dir}/#{f.name}"
    }
    begin
      @sftp.rmdir! "/home/listlibrary/#{dir}"
    rescue Net::SFTP::Exception => e
      raise unless e.code == Net::SFTP::Constants::StatusCodes::FX_NO_SUCH_FILE
    end
  end

end
