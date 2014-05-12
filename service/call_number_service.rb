require 'base62'

require_relative 'run_id_service'
require_relative 'sequence_id_service'
require_relative '../value/call_number'

# This should probably have a bitstring class broken out of it, but I don't
# expect to need to reuse those parts or change this algorithm anytime soon.

class CallNumberService
  attr_reader :ris, :sis

  SHUFFLE_TABLE = [41, 15, 20, 26, 6, 25, 23, 0, 16, 3, 18, 46, 42, 32, 31, 34, 1, 12, 7, 38, 33, 24, 2, 10, 14, 37, 5, 43, 13, 29, 27, 35, 21, 8, 44, 4, 9, 30, 36, 19, 39, 45, 40, 17, 22, 11, 28]

  def initialize ris=RunIdService.new, sis=SequenceIdService.new
    @ris = ris
    @sis = sis
  end

  def next!
    v = version
    # consume_sequence_id! may cause run_id to advance
    s = consume_sequence_id!
    r = ris.run_id
    CallNumber.new format_ids_to_call(v, r, s)
  end

  def version
    0
  end

  def consume_sequence_id!
    sis.consume_sequence_id!
  rescue SequenceIdExhaustion
    sequence_exhausted!
    sis.consume_sequence_id!
  end

  def sequence_exhausted!
    @ris.next!
    @sis.reset!
  end

  def format_ids_to_call v, r, s
    bitstring = combine(v, r, s)
    shuffled = stable_bitstring_shuffle bitstring
    shuffled.to_i(2).base62_encode.rjust(8, '0')
  end

  def combine v, r, s
    "%03b%030b%014b" % [v, r, s]
  end

  def stable_bitstring_shuffle bitstring
    raise ArgumentError, "Wrong length bitstring" unless bitstring.length == CALL_NUMBER_BITS
    (0..CALL_NUMBER_BITS-1).map { |i| bitstring[SHUFFLE_TABLE[i]] }.join('')
  end
end
