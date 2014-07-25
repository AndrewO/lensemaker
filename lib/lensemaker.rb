require "lensemaker/version"

module Lensemaker
  module Data
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
        source.map {|(key, child)| KeyValue.new(key, @lense.get(child)) }
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
      include Data

      def initialize(key); @key = key; end
        
      def get(source)
        source[@key]
      end

      def put(target, source)
        source.tap {|s| s[@key] = target }
      end

      def create(target)
        KeyValue.new(@key, target)
      end
    end

    class Plunge
      def initialize(key); @key = key; end

      def get(source)
        KeyValue.new(@key, source)
      end

      def put(target, _)
        create(target)
      end

      def create(target)
        target.value
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
        source.map(&:key).map {|key|
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
  end
end
