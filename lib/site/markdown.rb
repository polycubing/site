# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module Site
  # A prose page from content/*.md: a title line of front matter, then
  # markdown. Written by hand, rendered at build time.
  class Markdown
    attr_reader :title, :body

    def initialize(path:)
      text = File.read(path)
      if text.start_with?("---\n")
        _, front, rest = text.split(/^---\n/, 3)
        @title = YAML.safe_load(front)["title"]
        text = rest
      end
      @body = text
    end

    def html = Kramdown::Document.new(body, input: "GFM", hard_wrap: false).to_html
  end
end
