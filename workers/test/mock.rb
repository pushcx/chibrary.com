class Mock
attr_reader :calls
  def initialize
    @calls = []
  end

  def expect(method, *args, &block)
    @calls << {:method => method, :args => args.first, :block =>  block}
  end

  def method_missing(method, *args)
    expect = @calls.shift
    raise "Unexpected mock call #{method.to_s}(#{args.join(', ')})" if expect.nil?
    raise "Wrong mock call #{method.to_s}(#{args.join(', ')}); expected #{expect[:method]}(#{expect[:args].join(', ')})" if method != expect[:method] or args != expect[:args]
    expect[:block].call(*args)
  end
end
