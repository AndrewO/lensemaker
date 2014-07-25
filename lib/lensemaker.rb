require "lensemaker/version"

module Lensemaker
  module Data
=begin
    KeyValue = Struct.new(:key, :value) do
      def [](k)
        if k == self.key
          self.value
        else
          nil
        end
      end

      def to_h
        Hash.new.tap {|h| h[self.key] = self.value }
      end
    end
=end

    class HashOfLists < Hash
      def initialize
        Hash.new {|h, k| h[key] = [] }
      end
    end
  end

  module Lenses
    class Identity
      def get(source); source; end

      def put(target, _); target; end
        
      def create(target); target; end
    end

    class Value
      def initialize(value); @value = value; end

      def get(_); @value; end

      def put(_, _); @value; end

      def create(_); @value; end
    end

    class Map
      def initialize(lense)
        @lense = lense
      end

      def get(source)
        #source.map {|(key, child)| KeyValue.new(key, @lense.get(child)) }
        source.map {|(key, child)| Hash.new.tap {|h| h[key] = @lense.get(child) } }
      end

      def put(target, source)
        target.map {|(key, child)|
          @lense.put(child, source[key] || @lense.create(target))
        }
      end

      def create(target)
        target.map {|(key, child)|
          @lense.put(child, @lense.create(target))
        }
      end
    end

    class Pivot
      include Lensemaker::Data

      def initialize(key); @key = key; end
        
      def get(source)
        source[@key]
      end

      def put(target, source)
        source.tap {|s| s[@key] = target }
      end

      def create(target)
        # KeyValue.new(@key, target)
        Hash.new.tap {|h| h[@key] = target }
      end
    end

    class Plunge
      include Lensemaker::Data
      def initialize(key); @key = key; end

      def get(source)
        # KeyValue.new(@key, source)
        Hash.new.tap {|h| h[@key] = source }
      end

      def put(target, _)
        create(target)
      end

      def create(target)
        target[@key]
      end
    end

    class Flatten
      def get(source)
        source.inject(HashOfLists.new) {|accum, (key, value)|
          accum.tap {|a| a[key] << value }
        }
      end

      def put(target, source)
        # Preserve order of source but iterating through source keys.
        source.map(&:keys).flatten.map {|key|
          # Unsafe call; probably going to break
          target[key].pop
        } + target.values.flatten
      end

      def create(target)
        target.map {|(key, value)| KeyValue.new(key, value) }
      end
    end

    class Compose
      def initialize(lense_1, lense_2); @lense_1, @lense_2 = lense_1, lense_2; end

      def get(source)
        @lense_2.get(@lense_1.get(source))
      end

      def put(target, source)
        @lense_1.put(@lense_2.put(target, @lense_1.get(source)), source)
      end

      def create(target)
        @lense_2.create(@lense_1.create)
      end
    end

    class CastIn
      include Data
      def initialize(converter); @converter = converter; end

      def get(source)
        data_class = case source
        when Array
          List
        when [Boolean, NilClass, Numeric, String].include?(source)
          Value
        else
          Record
        end
        data_class.new(source)
      end

      def put(target, source)
        @converter.call(*(get(source) << target))
      end

      def create(target)
        @converter.call(*target)
      end
    end

    class CastOut
      include Data
      def initialize(converter); @converter = converter; end

      def get(source)
        @converter.call(*source)
      end

      def put(target, source)
        data_class = case target
        when Array
          List
        when [Boolean, NilClass, Numeric, String].include?(source)
          Value
        else
          Record
        end
        data_class.new(target) << source
      end

      def create(target)
        put(target, Empty)
      end
    end
  end
end
