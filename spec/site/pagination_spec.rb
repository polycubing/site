# frozen_string_literal: true

RSpec.describe Site::Pagination do
  it "cuts a listing into pages of a hundred, the first at the base path" do
    pages = described_class.new(entries: (1..250).to_a, base: "/9/").pages
    expect(pages.map(&:path)).to eq(["/9/", "/9/page/2/", "/9/page/3/"])
    expect(pages.map { it.rows.size }).to eq([100, 100, 50])
    expect(pages[1].previous_path).to eq("/9/")
    expect(pages[1].next_path).to eq("/9/page/3/")
    expect(pages.last.next_path).to be_nil
  end

  it "gives an empty listing one empty page" do
    pages = described_class.new(entries: [], base: "/open/").pages
    expect(pages.size).to eq(1)
    expect(pages.first.rows).to eq([])
  end
end
