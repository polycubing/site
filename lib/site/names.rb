# frozen_string_literal: true

module Site
  # Nicknames for the shapes worth naming, from content/names.yml. Edit the
  # file and the next build carries the change. Shapes without an entry have
  # no nickname and nothing is invented for them.
  class Names
    def initialize(path: ROOT.join("content", "names.yml"))
      @names = File.exist?(path) ? YAML.safe_load_file(path) || {} : {}
    end

    def [](id) = @names[id]

    def named = @names.keys
  end
end
