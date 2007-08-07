class Mock
attr_reader :calls
  def initialize
    @calls = []
  end

  def expect(method, *args, &proc)
    @calls << {:method => method, :args => args.first, :proc =>  proc}
  end

  def method_missing(method, *args)
    expect = @calls.shift
    raise "Unexpected mock call #{method.to_s}(#{args.join(', ')})" if expect.nil?
    raise "Wrong mock call #{method.to_s}(#{args.join(', ')}); expected #{expect[:method]}(#{expect[:args].join(', ')})" if method != expect[:method] or args != expect[:args]
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
