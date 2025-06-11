# frozen_string_literal: true

RSpec.shared_examples "an interface with required implementations" do |methods|
  methods.each do |method_name, arg_count|
    it "raises an error if ##{method_name} not implemented yet" do
      args = Array.new(arg_count, :foo)
      expect {
        subject.send(method_name.to_sym, *args)
      }.to raise_error("Not implemented yet!")
    end
  end
end
