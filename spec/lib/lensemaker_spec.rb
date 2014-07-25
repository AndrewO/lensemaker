require "lensemaker"

shared_examples "lense laws" do
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
    data(:src) { {a: value, b: rand } }

    describe "#get" do
      it "pivots the key up" do
        expect(subject.get(src)).to eq(value)
      end
    end

    describe "#put" do
      it "re-nests the target inside the key" do
        expect(subject.put(new_value, src).to_h[:a]).to eq(new_value)
      end
    end

    describe "#create" do
      it "creates a record with only that member" do
        expect(subject.create(new_value).to_h).to eq({a: new_value})
      end
    end
  end

  generative do
    data(:source) { {a: rand, b: rand} }
    data(:target) { rand }
    it_behaves_like "lense laws"
  end
end
