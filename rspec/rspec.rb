require 'singleton'

class Rspec
  include Singleton

  attr_accessor :events, :options, :attrs

  def it(desc, &proc)
    @events << {'desc' => desc.to_s, 'proc' => proc}
  end

  def let(key, &proc)
    @attrs ||= {}
    @attrs[key.to_s] = proc
  end

  def method_missing(method_name)
    super unless @attrs.keys.include?(method_name.to_s)
    @attrs[method_name.to_s].call
  end

  class << self
    def describe(desc, **opts, &proc)
      instance.events   ||= []
      instance.options  ||= {}
      instance.options.merge! opts
      instance.instance_eval &proc
    end

    def run
      instance.events.each do |event|
        room = RspecRoom.instance
        room.instance_eval &(event['proc'])
        room.reset
      end
    end
  end
end

class RspecRoom
  include Singleton

  attr_reader :old_method_map

  def allow(klass)
    RspecMock.new klass, true
  end

  def allow_any_instance_of(klass)
    RspecMock.new klass
  end

  def save_old_method(mock)
    @old_method_map ||= []
    unless mock.old_method.nil? || 
        @old_method_map.select{|e| e['klass'] == mock.old_method['klass'] && e['method'] == mock.old_method['method']}.size == 1
      @old_method_map << mock.old_method
    end
  end

  def receive(method)
    RspecResult.new method
  end

  def reset
    (@old_method_map || []).each do |old_method|
      old_method['class'].send :define_method, old_method['method'], &old_method['proc']
    end
    @old_method_map = []
  end

  def method_missing(method_name, *arg, &block)
    Rspec.instance.send :method_missing, method_name
  end
end

class RspecMock
  attr_accessor :klass, :singleton, :old_method

  def initialize(klass, singleton=false)
    @klass     = klass
    @singleton = singleton
  end

  def to(rspec_result)
    obj = (@singleton ? @klass : @klass.new)
    unless obj.respond_to?(rspec_result.method_name) || obj.respond_to_missing?(rspec_result.method_name)
      raise "#{@klass.to_s} not have #{'instance' unless @singleton} mehtod #{rspec_result.method_name.to_s}"
    end

    klass = (@singleton ? @klass.singleton_class : @klass)
    @old_method = {
      'class'   => klass,
      'method'  => rspec_result.method_name,
      'proc'    => obj.method(rspec_result.method_name)
    }
    klass.send :remove_method, rspec_result.method_name
    klass.send :define_method, rspec_result.method_name do |*arg|
      rspec_result.result
    end
    RspecRoom.instance.send :save_old_method, self
  end
end

class RspecResult
  attr_accessor :method_name, :result

  def initialize(method_name)
    @method_name = method_name
  end

  def and_return(hash)
    @result = hash
    self
  end
end

class RspecExpect

end

class A
  class << self
    def a; 10; end
  end
end

Rspec.describe 'test' do
  let(:a){ {'a'=>1} }

  it 'test' do
    puts A.a
    allow(A).to receive(:a).and_return(a)
    puts A.a
    allow(A).to receive(:a).and_return(100)
    puts A.a
  end

  it 'winse' do
    puts a
    puts A.a
  end
end

Rspec.run