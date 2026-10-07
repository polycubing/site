# frozen_string_literal: true

require "rouge"

module Site
  # Rouge's stylesheet, one theme per mode, scoped so the page's theme switch
  # carries the code with it. The tokens themselves are wrapped at view time
  # by assets/record.js, in Rouge's class names, because build-time markup
  # was ten times the size of the record on every one of 56,463 pages.
  class Highlight
    def self.css
      %w[light dark].map do |mode|
        Rouge::Theme.find("github.#{mode}").render(scope: %([data-bs-theme="#{mode}"] .highlight))
      end.join("\n")
    end
  end
end
