describe Swarm::Support do
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