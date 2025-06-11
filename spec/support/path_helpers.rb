# frozen_string_literal: true

require "pathname"

module PathHelpers
  def spec_path
    Pathname.new(File.expand_path('..', File.dirname(__FILE__)))
  end

  def fixtures_path
    spec_path.join('fixtures')
  end

  def fixture_path(fixture)
    fixtures_path.join(fixture)
  end
end
