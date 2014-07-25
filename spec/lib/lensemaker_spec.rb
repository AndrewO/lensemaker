require "lensemaker"

shared_examples "lense laws" do
  # Define :source and :target in containing context.
  generative do
    it "get-put: l.put (l.get s) s = s" do
      expect(subject.put(subject.get(source), source)).to eq(source)
    end

    it "put-get: l.get (l.put t s) = t" do
      expect(subject.get(subject.put(target, source))).to eq(target)
    end

    it "create-get: l.get (l.create t) = t" do
      expect(subject.get(subject.create(target))).to eq(target)
    end
  end
end

describe Lensemaker::Lenses::Identity do
  generative do
    data(:source) { rand }
    describe "#get" do
      it "passes the source through untouched" do
        expect(subject.get(source)).to eq(source)
      end
    end
  end

  generative do
    describe "#put" do
      data(:source) { rand }
      data(:target) { rand }
      it "overrides the source with the target" do
        expect(subject.put(target, source)).to eq(target)
      end
    end
  end

  generative do
    describe "#create" do
      data(:target) { rand }
      # Is this right? Or should it no-op?
      it "passes the target through" do
        expect(subject.create(target)).to eq(target)
      end
    end
  end

  generative do
    data(:source) { rand }
    data(:target) { rand }
    it_behaves_like "lense laws"
  end
end

describe Lensemaker::Lenses::Pivot do
  subject { described_class.new(:a) }

  generative do
    data(:value) { rand }
    data(:new_value) { rand }
    data(:src) { {a: value } }

    describe "#get" do
      it "pivots the key up" do
        expect(subject.get(src)).to eq(value)
      end
    end

    describe "#put" do
      it "re-nests the target inside the key" do
        expect(subject.put(new_value, src)[:a]).to eq(new_value)
      end
    end

    describe "#create" do
      it "creates a record with only that member" do
        expect(subject.create(new_value)).to eq({a: new_value})
      end
    end
  end

  generative do
    data(:source) { {a: rand } }
    data(:target) { rand }
    it_behaves_like "lense laws"
  end
end

describe Lensemaker::Lenses::Plunge do
  generative do
    data(:source) { rand }
    data(:new_value) { {a: rand } } 
    subject { described_class.new(:a) }

    describe "#get" do
      it "nests the source data using the given key" do
        expect(subject.get(source)).to eq({a: source})
      end
    end

    describe "#put" do
      it "unwraps the target using the key" do
        expect(subject.put(new_value, source)).to eq(new_value[:a])
      end
    end

    describe "#create" do
      it "unwraps the target using the key" do
        expect(subject.create(new_value)).to eq(new_value[:a])
      end
    end
  end

  generative do
    data(:source) { rand }
    data(:target) { {a: rand } }
    subject { described_class.new(:a) }
    it_behaves_like "lense laws"
  end
end
