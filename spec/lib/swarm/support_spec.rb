describe Swarm::Support do
  describe ".deep_merge" do
    let(:h1) { { :foo => :bar, :baz => [1, 2, 3], :crayons => { :brand => :crayola } } }
    let(:h2) { { :baz => [3, 4], :crayons => { :number => 4 } } }
    it "deep merges hashes and overrides arrays by default" do
      expect(described_class.deep_merge(h1, h2)).to eq({
        :foo => :bar,
        :baz => [3, 4],
        :crayons => { :brand => :crayola, :number => 4 }
      })
    end

    it "concatenates arrays if requested" do
      expect(described_class.deep_merge(h1, h2, :combine_arrays => :concat)).to eq({
        :foo => :bar,
        :baz => [1, 2, 3, 3, 4],
        :crayons => { :brand => :crayola, :number => 4 }
      })
    end

    it "reduces combined arrays to uniq values if requested" do
      expect(described_class.deep_merge(h1, h2, :combine_arrays => :uniq)).to eq({
        :foo => :bar,
        :baz => [1, 2, 3, 4],
        :crayons => { :brand => :crayola, :number => 4 }
      })
    end
  end

  describe ".symbolize_keys!" do
    it "symbolizes keys in given hash" do
      hsh = { :fancy => { "blue" => "green"}, "what" => 42 }
      described_class.symbolize_keys!(hsh)
      expect(hsh).to eq({
        :fancy => { "blue" => "green"}, :what => 42
      })
    end
  end

  describe '.camelize' do
    it 'turns underscored string into camelcase' do
      expect(described_class.camelize('foo_bar_One_two_3')).to eq('FooBarOneTwo3')
    end

    it 'deals with nested classes' do
      expect(described_class.camelize('foo_bar/bar_foo')).to eq('FooBar::BarFoo')
    end

    it "doesn't modify strings that are already camelized" do
      expect(described_class.camelize('FooBar::BarFoo')).to eq('FooBar::BarFoo')
    end
  end

  describe '.constantize' do
    before :each do
      class Whatever
        Smoothies = 'tasty'
      end
      class Boojus
      end
    end

    after :each do
      Object.send(:remove_const, :Whatever)
    end

    it 'returns value of constant with given name' do
      expect(described_class.constantize('Whatever')::Smoothies).to eq('tasty')
    end

    it 'works with nested constants' do
      expect(described_class.constantize('Whatever::Smoothies')).to eq('tasty')
    end

    it 'does not check inheritance tree' do
      expect {
        described_class.constantize('Whatever::Boojus')
      }.to raise_error(NameError)
    end
  end
end