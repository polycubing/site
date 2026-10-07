# frozen_string_literal: true

module Site
  # Writes the whole site into public/: assets, prose pages, the home page,
  # one index per size (paginated), one page per tag (paginated), and one
  # page per shape.
  class Build
    TAGS = {
      "non-tilers" => "Non-tilers",
      "open" => "Open",
      "heesch/1" => "Heesch number 1",
      "heesch/2" => "Heesch number 2 or more",
      "box" => "Box tilers",
      "torus" => "Periodic tilers",
      "chiral" => "Chiral",
      "achiral" => "Achiral",
      "corona" => "With a corona witness"
    }.freeze

    def self.run(data: ROOT.join("..", "census", "data"), output: ROOT.join("public"), max_size: nil, report: $stdout)
      new(data:, output:, max_size:, report:).run
    end

    def initialize(data:, output:, max_size: nil, report: nil)
      @names = Names.new
      @catalog = Catalog.new(data:, names: @names, max_size:)
      @output = Pathname(output)
      @report = report
    end

    def run
      assets
      prose
      home
      @catalog.sizes.each { size_index(it) }
      TAGS.each_key { tag(it) }
      shapes
      say "built #{@catalog.entries.size} shapes into #{@output}"
    end

    private

    def say(line) = @report&.puts(line)

    def write(path, html)
      file = @output.join(path.delete_prefix("/"), "index.html")
      FileUtils.mkdir_p(file.dirname)
      File.write(file, html)
    end

    def assets
      FileUtils.mkdir_p(@output.join("assets"))
      Dir.glob(ROOT.join("vendor", "*")).each { FileUtils.cp(it, @output.join("assets")) }
      Dir.glob(ROOT.join("assets", "*")).each { FileUtils.cp(it, @output.join("assets")) }
      File.write(@output.join("assets", "rouge.css"), "#{Highlight.css}\n")
      File.write(@output.join("CNAME"), "polycubes.org\n")
    end

    def prose
      Dir.glob(ROOT.join("content", "*.md")).each do |path|
        slug = File.basename(path, ".md")
        next if slug == "home"

        page = Markdown.new(path:)
        write("/#{slug}/", Page.new(template: "prose", title: page.title, locals: { page: }).render)
      end
    end

    def home
      page = Markdown.new(path: ROOT.join("content", "home.md"))
      write("/", Page.new(template: "home", title: nil, locals: { page:, counts: @catalog.counts, names: @names }).render)
    end

    def size_index(size)
      entries = @catalog.entries_of(size)
      highlights = entries.reject { it.verdict == "tiler" }
      Pagination.new(entries:, base: "/#{size}/").pages.each do |page|
        locals = { page:, heading: "#{number_name(size).capitalize}, n = #{size}", intro: "#{entries.size} shapes.",
                   highlights: page.number == 1 ? highlights : [] }
        write(page.path, Page.new(template: "listing", title: "#{number_name(size)} (n = #{size})", locals:).render)
      end
    end

    def tag(tag)
      entries = @catalog.tagged(tag)
      Pagination.new(entries:, base: "/#{tag}/").pages.each do |page|
        html = Page.new(template: "listing", title: TAGS[tag],
                        locals: { page:, heading: TAGS[tag], highlights: [], intro: "#{entries.size} shapes." }).render
        write(page.path, html)
      end
    end

    def shapes
      @catalog.sizes.each do |size|
        @catalog.each_record(size) do |record|
          write(record.path, Page.new(template: "shape", title: record.title, locals: { record: }).render)
        end
        say "  n=#{size} done"
      end
    end

    def number_name(size)
      %w[monocube dicube tricubes tetracubes pentacubes hexacubes heptacubes octacubes nonacubes][size - 1] || "#{size}-cubes"
    end
  end
end
