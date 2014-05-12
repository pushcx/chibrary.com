class SequenceIdExhaustion < RangeError ; end

class SequenceIdService
  # has 14 bits allocated to it in the CallNumber
  MAX_SEQUENCE_ID = 2 ** 14 - 1

  def initialize
    reset!
  end

  def reset!
    @sequence_id = 0
  end

  def consume_sequence_id!
    raise SequenceIdExhaustion if @sequence_id > MAX_SEQUENCE_ID
    @sequence_id.tap { increment! }
  end

  private

  def increment!
    @sequence_id += 1
  end
end
