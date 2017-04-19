my_const = 'winse'

class B
  # puts my_const   # => Error

  def my_method
    # puts my_const   # => Error
  end
end

B.new.my_method

# 扁平化作用域 (共享变量)
A = Class.new do
  puts my_const   # => 'winse'

  define_method :my_method do
    puts my_const   # => 'winse'
  end
end

A.new.my_method