class ThreadList
  attr_reader :slug, :year, :month

  def initialize slug, year, month
    @slug, @year, @month = slug, year, month

    begin
      data = $riak[key] 
      @threads      = data['threads']
      @call_numbers = data['call_numbers']
    rescue NotFound
      @threads      = []
      @call_numbers = {}
    end
  end

  def to_yaml_properties ; %w{@source @call_number @message_id @references @subject @date @from @no_archive @key @slug @message} ; end

  def add_thread thread
    thread_call_number = thread.call_number
    @threads << { :call_number => thread_call_number, :subject => thread.n_subject, :messages => thread.count }
    thread.each do |container| 
      next if container.empty? or container.call_number == thread.call_number
      @call_numbers[container.call_number] = "/#{@slug}/#{@year}/#{@month}/#{thread.call_number}"
    end
  end

  def add_redirected_thread call_numbers, year, month
    call_numbers.each do |call_number|
      # redirect to the message, which will redirect to its new parent thread
      @call_numbers[call_number] = "/#{@slug}/#{year}/#{month}/#{call_number}"
    end
  end

  def thread_count  ; @threads.length      ; end
  def message_count ; @call_numbers.length ; end

  # ThreadList does assume that threads are passed to add_thread in temporal order, which the threader does.
  def previous_thread call_number
    index = thread_index_of call_number
    if index == 0
      previously = Time.utc(@year, @month).plus_month(-1)
      year  = previously.year
      month = "%02d" % previously.month
      previous_thread = ThreadList.new(@slug, year, month).last_thread
    else
      year, month = @year, @month
      previous_thread = @threads[index - 1]
    end
    bundle_thread previous_thread, year, month
  end

  def next_thread call_number
    index = thread_index_of call_number
    if index == thread_count - 1
      nextly = Time.utc(@year, @month).plus_month(1)
      year  = nextly.year
      month = "%02d" % nextly.month
      next_thread = ThreadList.new(@slug, year, month).first_thread
    else
      year, month = @year, @month
      next_thread = @threads[index + 1]
    end
    bundle_thread next_thread, year, month
  end

  def redirect? call_number
    redirect = @call_numbers[call_number]
    return redirect unless redirect == call_number
  end

  def store
    $riak[key] = { :threads => @threads, :call_numbers => @call_numbers } unless @call_numbers.empty?
  end

  def self.year_counts slug
    years = {}
    thread_lists = $riak.list "list/#{slug}/thread_list"
    thread_lists.each(true) do |key|
      next unless key =~ /^\d{4}\/\d{2}$/
      year, month = key.split('/')
      thread_list = ThreadList.new slug, year, month
      years[year] ||= {}
      years[year][month] = { :threads => thread_list.thread_count, :messages => thread_list.message_count }
    end
    return years.sort
  rescue NotFound
    return []
  end

  protected
  def first_thread ; @threads[0]  ; end
  def last_thread  ; @threads[-1] ; end

  private
  def key
    "list/#{@slug}/thread_list/#{@year}/#{@month}"
  end

  def thread_index_of call_number
    @threads.each_with_index { |thread, i| return i if thread['call_number'] == call_number }
    raise RuntimeError, "Thread #{call_number} not in ThreadList #{@slug}/#{@year}/#{@month}"
  end

  def bundle_thread thread, year, month
    # returns the hash of only what the controller needs, or nil if there isn't a next/previous thread
    return nil if thread.nil?
    return { :slug => @slug, :year => year, :month => month, :call_number => thread['call_number'], :subject => thread['subject'] }
  end
end
