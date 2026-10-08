# frozen_string_literal: true

RSpec.describe Site::Record do
  let(:names) { Site::Names.new }

  def record(id) = described_class.new(directory: File.join(FIXTURES, "data", id), names:)

  describe "#headline" do
    it "says a box tiler fills a box" do
      expect(record("1/1").headline).to eq("Tiles space. 1 copies fill a 1×1×1 box, and boxes stack.")
    end

    it "says a periodic tiler repeats on a lattice" do
      expect(record("9/2500").headline).to match(/Tiles space periodically\. \d+ copies per repeating block, on a lattice of index 54/)
    end

    it "says a non-tiler's Heesch number and what refuted it" do
      expect(record("8/1309").headline).to eq(
        "Does not tile space. Heesch number 1: copies can wrap it once, and provably never 2 times. " \
        "The refutation is a DRAT proof checked by drat-trim."
      )
    end

    it "says a mirrored non-tiler leans on its twin" do
      expect(record("9/42969").headline).to end_with("mirrored from 9/42947.")
    end

    it "says what an open shape survived and what is undecided" do
      expect(record("9/2127").headline).to eq(
        "Survived every test within its budgets. No box tiling through volume 128. No periodic tiling through lattice index 72. " \
        "Wraps itself 2 times, with a verified witness. Whether it wraps 3 times is undecided."
      )
    end
  end

  describe "#how" do
    it "is one phrase per verdict" do
      expect([record("1/1"), record("9/2500"), record("8/1309"), record("9/2127")].map(&:how))
        .to eq(["box 1×1×1", "torus, index 54", "Heesch 1", "Heesch ≥ 2"])
    end
  end

  describe "#tags" do
    it "files the staircase under open, Heesch 2, achiral, and corona" do
      expect(record("9/2127").tags).to contain_exactly("open", "heesch/2", "achiral", "corona")
    end

    it "files the ring under non-tilers, Heesch 1, achiral, and corona" do
      expect(record("8/1309").tags).to contain_exactly("non-tilers", "heesch/1", "achiral", "corona")
    end

    it "files a periodic tiler under torus" do
      expect(record("9/2500").tags).to include("torus")
    end
  end

  describe "#layers" do
    it "gives an open shape its shape and both coronas, cumulatively" do
      layers = record("9/2127").layers
      expect(layers.map { it[:label] }).to eq(["shape", "corona 1", "corona 2"])
      expect(layers[0][:copies].size).to eq(1)
      expect(layers[2][:copies].size).to eq(1 + 27 + 201)
      expect(layers[2][:copies].map { it[:ring] }.uniq).to eq([0, 1, 2])
    end

    it "gives a tiler its shape and a chunk of the tiling" do
      layers = record("9/2500").layers
      expect(layers.map { it[:label] }).to eq(%w[shape tiling])
      expect(layers[1][:copies].size).to be > 1
      expect(layers[1][:copies].flat_map { it[:cells] }.uniq.size).to eq(layers[1][:copies].flat_map { it[:cells] }.size)
    end
  end

  describe "#nickname" do
    it "comes from content/names.yml" do
      expect(record("9/2127").nickname).to eq("the staircase")
      expect(record("9/2500").nickname).to be_nil
    end
  end

  describe "#downloads" do
    it "points at the census through jsDelivr" do
      urls = record("9/2127").downloads.map { it[:url] }
      expect(urls).to include("https://cdn.jsdelivr.net/gh/polycubing/census@main/data/9/2127/model.stl",
                              "https://cdn.jsdelivr.net/gh/polycubing/census@main/data/9/2127/corona2.json")
      expect(urls.grep(/tiling/)).to be_empty
    end

    it "points tiling chunks at the bucket, with their colours beside them" do
      urls = record("9/2500").downloads.map { it[:url] }
      expect(urls).to include("https://polycubes.s3.us-west-2.amazonaws.com/public/meshes/9/2500/tiling.obj",
                              "https://polycubes.s3.us-west-2.amazonaws.com/public/meshes/9/2500/tiling.mtl")
    end
  end
end
