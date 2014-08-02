module Chibrary

class ThreadLinkRepo
  attr_reader :thread_link

  def initialize thread_link
    @thread_link = thread_link
  end

  def serialize
    {
      call_number: thread_link.call_number,
      subject:     thread_link.subject,
    }
  end
end

end # Chibrary
