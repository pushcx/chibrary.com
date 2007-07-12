class Mock
  def initialize
    @calls = []
  end

  def expect(method, *args, &block)
    @calls << [method, args.first, block]
  end

  def method_missing(method, *args)
    expect = @calls.first
    raise "Unexpected mock call #{method.to_s}(#{args.join(', ')})" if method != expect[0] or args != expect[1]
    @calls.shift
    expect[2].call(*args)
  end
end
