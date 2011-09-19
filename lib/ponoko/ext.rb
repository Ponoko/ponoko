module PonokoArrayExtensions
  def to_multipart key
    prefix = "#{key}[]"
    collect {|a| a.to_multipart(prefix)}.flatten
  end
  
  def to_query key
    prefix = "#{key}[]"
    collect { |value| value.to_query(prefix) }.flatten
  end
  
  def to_params
    collect {|a| a.to_params }.flatten
  end
end

module PonokoHashExtensions
  def to_multipart key = nil
    collect {|k, v| v.to_multipart(key ? "#{key}[#{k}]" : k)}.flatten
  end
  
  def to_query key = nil
    collect {|k, v| v.to_query(key ? "#{key}[#{k}]" : k)}.flatten.join '&'
  end
  
  def to_params
    self
  end  
end

module PonokoStringExtensions
  def to_multipart key
    "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n" + 
    "#{self}\r\n"
  end
  
  def to_query key = nil
    key ? URI.escape("#{key}=#{self}")
        : URI.escape(self)
  end
end

module PonokoFileExtensions
  def to_multipart key = nil
    "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{File.basename(self.path)}\"\r\n" +
    "Content-Transfer-Encoding: binary\r\n" +
    "Content-Type: application/#{File.extname(self.path)}\r\n\r\n" + 
    "#{self.read}\r\n"
  end
end

module PonokoFixnumExtensions
  def to_query key = nil
    key ? URI.escape("#{key}=#{self}")
        : URI.escape(self)
  end
end

module PonokoFloatExtensions
  def to_query key = nil
    key ? URI.escape("#{key}=#{self}")
        : URI.escape(self)
  end
end

module PonokoTrueClassExtensions
  def to_multipart key
    "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n" + 
    "1\r\n"
  end
end

module PonokoNilClassExtensions
  def to_query key = nil
    ""
  end
end

class Array
  include PonokoArrayExtensions
end

class Hash
  include PonokoHashExtensions
end

class String
  include PonokoStringExtensions
end

class File
  include PonokoFileExtensions
end

class Fixnum
  include PonokoFixnumExtensions
end

class Float
  include PonokoFloatExtensions
end

class TrueClass
  include PonokoTrueClassExtensions
end

class NilClass
  include PonokoNilClassExtensions
end
