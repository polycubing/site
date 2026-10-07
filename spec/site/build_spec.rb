# frozen_string_literal: true

RSpec.describe Site::Build do
  around { |example| Dir.mktmpdir { |dir| @output = dir and example.run } }

  before { described_class.run(data: File.join(FIXTURES, "data"), output: @output, report: nil) }

  def page(path) = File.read(File.join(@output, path, "index.html"))

  it "writes one page per shape with its verdict and viewer data" do
    html = page("9/2127")
    expect(html).to include("the staircase", ">OPEN<", 'id="page" type="application/json"', "corona 2")
    expect(html).to include('<script src="/assets/viewer.js">')
  end

  it "writes the home page with the scoreboard" do
    html = page("")
    expect(html).to include("A Polycube Tiling Census", 'href="/8/1309/"')
    expect(html).to match(%r{<td class="text-end mono">4</td>})
  end

  it "writes an index per size with the interesting shapes first" do
    html = page("9")
    expect(html).to include("Worth a look", 'href="/9/2127/"', 'href="/9/48258/"')
  end

  it "writes a page per tag" do
    expect(page("non-tilers")).to include('href="/8/1309/"', 'href="/9/48258/"', 'href="/9/42969/"')
    expect(page("open")).to include('href="/9/2127/"')
    expect(page("heesch/1")).not_to include('href="/9/2127/"')
  end

  it "writes the prose pages and the assets" do
    expect(page("glossary")).to include("Heesch number")
    expect(File).to exist(File.join(@output, "assets", "viewer.js"))
    expect(File).to exist(File.join(@output, "assets", "rouge.css"))
    expect(File).to exist(File.join(@output, "assets", "bootstrap.min.css.map"))
    expect(File.read(File.join(@output, "CNAME"))).to eq("polycubes.org\n")
  end
end
