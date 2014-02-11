require 'ostruct'

class DeepStruct < OpenStruct
  def initialize(hash=nil)
    @table = {}
    @hash_table = {}

    if hash
      hash.each do |k,v|
        @table[k.to_sym] = v

        @table[k.to_sym] = v.map do |o|
            o.is_a?(Hash) ? self.class.new(o) : o
        end if v.is_a? Array

        @table[k.to_sym] = self.class.new(v) if v.is_a? Hash

        @hash_table[k.to_sym] = v

        new_ostruct_member(k)
      end
    end
  end

  def to_h
    @hash_table
  end

end
