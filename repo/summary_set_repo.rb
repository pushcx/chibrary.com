require_relative 'riak_repo'
require_relative 'summary_container_repo'

class SummarySetRepo
  include RiakRepo

  attr_reader :sym, :summary_containers

  def initialize sym, summary_containers
    @sym, @summary_containers = sym, summary_containers
  end

  def extract_key
    self.class.build_key sym
  end

  def serialize
    summary_containers.map { |sc| SummaryContainerRepo.new(sc).serialize }
  end

  def self.build_key sym
    sym.to_key
  end

  def self.deserialize ary
    ary.map { |h| SummaryContainerRepo.deserialize(h) }
  end

  def self.find sym
    key = build_key sym
    deserialize bucket[key]
  end
end
