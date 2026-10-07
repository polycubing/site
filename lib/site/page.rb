# frozen_string_literal: true

module Site
  # One HTML page: a template rendered inside the layout. Templates are ERB
  # under templates/, with the helpers below in scope.
  class Page
    def initialize(template:, title:, locals: {})
      @template = template
      @title = title
      @locals = locals
    end

    def render
      body = evaluate(@template)
      evaluate("layout", body:)
    end

    private

    def evaluate(name, extra = {})
      source = File.read(ROOT.join("templates", "#{name}.erb"))
      Context.new(@title, @locals.merge(extra)).render(ERB.new(source, trim_mode: "-"))
    end

    class Context
      include ERB::Util

      attr_reader :title

      def initialize(title, locals)
        @title = title
        locals.each { |name, value| instance_variable_set("@#{name}", value) }
        @locals = locals
      end

      def render(erb) = erb.result(binding)

      def method_missing(name, *arguments)
        return @locals.fetch(name) if arguments.empty? && @locals.key?(name)

        super
      end

      def respond_to_missing?(name, include_private = false) = @locals.key?(name) || super

      def json(value) = JSON.generate(value)

      def number(value) = value.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
    end
  end
end
