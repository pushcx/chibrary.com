class Mock
  attr_reader :calls, :called

  # the stub arg makes it just record all calls
  def initialize stub=false
    @calls = []
    @called = []
    @stub = stub
  end

  # Pass nil for args to ignore the actual args in the call.
  # Proc is optional; default is empty proc returning nil.
  def expect(method, *args, &proc)
    @calls << {:method => method, :args => args.first, :proc => (proc or Proc.new{})}
  end

  def method_missing(method, *args)
    @called << {:method => method, :args => args}
    return if @stub

    expect = @calls.shift
    raise "Unexpected mock call #{method.to_s}(#{args.join(', ')})" if expect.nil?
    raise "Wrong mock call #{method.to_s}(#{args.join(', ')}); expected #{expect[:method]}(#{expect[:args].join(', ')})" if method != expect[:method] or (expect[:args] != nil and args != expect[:args])
    expect[:proc].call(*args)
  end

  def fail_if_not_empty
    # Empty the call stack so that this obj doesn't throw errors for
    # every later test between now and this object getting gc'd
    calls, @calls = @calls, []
    raise "Mock calls uncalled: \n" + calls.collect { |call| "#{call[:method]}(#{call[:args]} { #{call[:proc] })" }.join(" ") unless calls.empty?
  end
end

# hook into teardown to detect unused mock calls
class Test::Unit::TestCase
  def teardown
    finish_mocks
  end

  def finish_mocks
    ObjectSpace.each_object(Mock) do |m|
      m.fail_if_not_empty
    end
  end
end
