require 'base62'

require_relative 'run_id_generator'
require_relative 'sequence_id_generator'
require_relative 'call_number'

# This should probably have a bitstring class broken out of it, but I don't
# expect to need to reuse those parts or change this algorithm anytime soon.

class CallNumberGenerator
  attr_reader :rig, :sig

  SHUFFLE_SEED = 1234

  def initialize rig=RunIdGenerator.new, sig=SequenceIdGenerator.new
    @rig = rig
    @sig = sig
  end

  def next!
    v = version
    # consume_sequence_id! may cause run_id to advance
    s = consume_sequence_id!
    r = rig.run_id
    CallNumber.new format_ids_to_call(v, r, s)
  end

  def version
    0
  end

  def consume_sequence_id!
    sig.consume_sequence_id!
  rescue SequenceIdExhaustion
    sequence_exhausted!
    sig.consume_sequence_id!
  end

  def sequence_exhausted!
    @rig.next!
    @sig.reset!
  end

  def format_ids_to_call v, r, s
    bitstring = combine(v, r, s)
    shuffled = stable_bitstring_shuffle bitstring
    shuffled.to_i(2).base62_encode
  end

  def combine v, r, s
    "%03b%030b%014b" % [v, r, s]
  end

  def stable_bitstring_shuffle bitstring
    bitstring.split('').shuffle(random: Random.new(SHUFFLE_SEED)).join('')
  end
end
