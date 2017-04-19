module StringExtensions
  refine String do
    %w(debug info warnning error).each do |name|
      define_method "to_#{name}" do
        to_log name
      end
    end

    def to_log(level)
      "[#{level}]" + self
    end
  end
end

module A
  using StringExtensions
  puts "hahaha".to_info     # => "[info]hahaha"
end

class B
  # include A
  using StringExtensions

  puts "fire in the house!".to_warnning   # => "[warnning]fire in the house!"
end

# puts "hahaha".to_info   # => NoMethod "to_info"

# 细化的陷阱
class C
  def show_c
    show "c"
  end

  def show(name)
    puts name
  end
end

module CTest
  refine C do
    def show(name)
      puts "[-.-]#{name}"
    end
  end
end

Class.new do
  using CTest
  C.new.show('winse') # => "[-.-]winse"
  C.new.show_c        # => "c"
end