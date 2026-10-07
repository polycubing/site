# frozen_string_literal: true

require "tmpdir"
require_relative "../lib/site"

FIXTURES = File.expand_path("fixtures", __dir__)

RSpec.configure do |config|
  config.expect_with(:rspec) { it.include_chain_clauses_in_custom_matcher_descriptions = true }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
