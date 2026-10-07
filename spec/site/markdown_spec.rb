# frozen_string_literal: true

RSpec.describe Site::Markdown do
  it "takes its title from the front matter and renders the rest" do
    page = described_class.new(path: Site::ROOT.join("content", "glossary.md"))
    expect(page.title).to eq("Glossary")
    expect(page.html).to include('<h2 id="heesch-number">Heesch number</h2>')
  end
end
