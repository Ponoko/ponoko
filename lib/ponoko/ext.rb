class Array
  def to_multipart key = nil
    prefix = "#{key}[]"
    collect {|a| a.to_multipart(prefix)}.flatten
  end
  
  def to_query key = nil
    prefix = "#{key}[]"
    collect { |value| value.to_query(prefix) }.flatten
  end
  
  def to_params
    collect {|a| a.to_params }.flatten
  end
end

class Hash
  def to_multipart key = nil
    collect {|k, v| v.to_multipart(key ? "#{key}[#{k}]" : k)}.flatten
  end
  
  def to_query key = nil
    collect {|k, v| v.to_query(key ? "#{key}[#{k}]" : k)}.flatten
  end
  
  def to_params
    self
  end  
end

class String
  def to_multipart key
    "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n" + 
    "#{self}\r\n"
  end
  
  def to_query key
    {key => self}
  end
end

class File
  def to_multipart key = nil
    "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{File.basename(self.path)}\"\r\n" +
    "Content-Transfer-Encoding: binary\r\n" +
    "Content-Type: application/#{File.extname(self.path)}\r\n\r\n" + 
    "#{self.read}\r\n"
  end
end

