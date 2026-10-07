# frozen_string_literal: true

require "erb"
require "fileutils"
require "json"
require "yaml"

require "census/assembly"
require "census/lattice"
require "census/polycube"
require "census/rotation"

require_relative "site/build"
require_relative "site/catalog"
require_relative "site/highlight"
require_relative "site/layers"
require_relative "site/markdown"
require_relative "site/names"
require_relative "site/page"
require_relative "site/pagination"
require_relative "site/record"

module Site
  ROOT = Pathname(File.expand_path("..", __dir__))
end
