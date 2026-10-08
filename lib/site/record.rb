# frozen_string_literal: true

module Site
  # One shape's record, read from its folder in the census, with everything a
  # page says about it: the verdict in plain words, how it was settled, the
  # tags it belongs under, and the viewer's layers.
  class Record
    attr_reader :directory, :fields, :nickname

    def initialize(directory:, names:)
      @directory = directory
      @fields = JSON.parse(File.read(File.join(directory, "shape.json")), symbolize_names: true)
      @nickname = names[id]
    end

    def id = fields[:id]

    def size = fields[:n]

    def index = Integer(id.split("/").last)

    def path = "/#{id}/"

    def title = nickname ? "#{id}, #{nickname}" : id

    def verdict = fields[:verdict]

    def certificate = fields[:certificate] || {}

    def kind = certificate[:type]

    def refutation_kind = certificate[:refutation_kind]

    def chiral? = fields[:chiral] == true

    def mirror_id = fields[:mirror_id]

    def mirrored? = fields.dig(:credits, :solved_by).to_s.include?("mirrored") || certificate[:provenance] == "derived"

    def heesch = fields[:heesch]

    def corona_witnessed = fields.dig(:reached, :corona_sat)

    def stages = fields[:stages] || []

    def cells = fields[:cells]

    def extent = cells.transpose.map { |axis| axis.max - axis.min + 1 }

    def raw = File.read(File.join(directory, "shape.json"))

    def layers = @layers ||= Layers.new(record: fields, directory:).to_a

    # One line, for a listing.
    def how
      case verdict
      when "tiler"     then kind == "box" ? "box #{certificate[:box].join('×')}" : "torus, index #{lattice_index}"
      when "non_tiler" then "Heesch #{heesch}"
      when "open"      then corona_witnessed ? "Heesch ≥ #{corona_witnessed}" : "open"
      else "unresolved"
      end
    end

    def badge = { "tiler" => "TILER", "non_tiler" => "NON-TILER", "open" => "OPEN" }.fetch(verdict, "UNRESOLVED")

    # A paragraph, for the shape's own page.
    def headline
      case verdict
      when "tiler"     then tiler_headline
      when "non_tiler" then non_tiler_headline
      when "open"      then open_headline
      else "No verdict yet."
      end
    end

    def tags
      tags = []
      tags << "non-tilers" if verdict == "non_tiler"
      tags << "open" if verdict == "open"
      tags << "box" if verdict == "tiler" && kind == "box"
      tags << "torus" if verdict == "tiler" && kind == "torus"
      tags << "heesch/#{heesch}" if heesch
      tags << "heesch/#{corona_witnessed}" if verdict == "open" && corona_witnessed
      tags << (chiral? ? "chiral" : "achiral")
      tags << "corona" if layers.any? { it[:label].start_with?("corona") }
      tags
    end

    # Records and small meshes come from the census repository through
    # jsDelivr. Tiling chunks are too big for git and live in the bucket.
    def downloads
      base = "https://cdn.jsdelivr.net/gh/polycubing/census@main/data/#{id}"
      meshes = "https://polycubes.s3.us-west-2.amazonaws.com/public/meshes/#{id}"
      list = [["model.stl", "the shape, printable", base]]
      list << ["tiling.obj", "a chunk of the tiling, one colour per copy", meshes] if verdict == "tiler"
      list << ["tiling.mtl", "the chunk's colours, saved beside the .obj", meshes] if verdict == "tiler"
      layers.filter_map { it[:label][/corona (\d+)/, 1] }.each do |depth|
        list << ["corona#{depth}.json", "the depth-#{depth} witness, as placements", base]
      end
      list << ["shape.json", "the record", base]
      list.map { |name, what, from| { name:, what:, url: "#{from}/#{name}" } }
    end

    private

    def lattice_index = Census::Lattice.new(basis: certificate[:lattice]).index

    def copies = certificate[:placements].size

    def tiler_headline
      origin = mirrored? ? " The certificate is the mirror image of #{mirror_id}'s." : ""
      if kind == "box"
        "Tiles space. #{copies} copies fill a #{certificate[:box].join('×')} box, and boxes stack.#{origin}"
      else
        "Tiles space periodically. #{copies} copies per repeating block, on a lattice of index #{lattice_index}. " \
          "No box through volume #{fields.dig(:budgets, :box_max_volume)} was found first.#{origin}"
      end
    end

    def non_tiler_headline
      wraps = heesch == 1 ? "once" : "#{heesch} times"
      evidence = case refutation_kind
                 when "proof"       then "a DRAT proof checked by drat-trim"
                 when "cube_proofs" then "#{certificate.dig(:checked, :proofs)} cube proofs, each checked by drat-trim"
                 when "ledger"      then "cube-and-conquer ledgers, every cube refuted"
                 else "a refutation"
                 end
      origin = mirrored? ? ", mirrored from #{mirror_id}" : ""
      "Does not tile space. Heesch number #{heesch}: copies can wrap it #{wraps}, and provably never #{heesch + 1} times. " \
        "The refutation is #{evidence}#{origin}."
    end

    def open_headline
      budgets = fields[:budgets] || {}
      parts = ["Survived every test within its budgets."]
      parts << "No box tiling through volume #{budgets[:box_max_volume]}." if budgets[:box_max_volume]
      parts << "No periodic tiling through lattice index #{budgets[:torus_max_index]}." if budgets[:torus_max_index]
      parts << "Wraps itself #{corona_witnessed == 1 ? 'once' : "#{corona_witnessed} times"}, with a verified witness." if corona_witnessed
      attempted = (fields[:attempts] || []).map { it[:depth] }.max
      parts << "Whether it wraps #{attempted} times is undecided." if attempted
      parts.join(" ")
    end
  end
end
