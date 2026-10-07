# frozen_string_literal: true

module Site
  # What the viewer draws for a record: a list of layers, each a label and
  # the copies shown when that layer is selected, every copy a list of cells
  # and a ring number for colouring. Computed in Ruby with the census's own
  # geometry, so the page's JavaScript only ever draws cubes.
  class Layers
    def initialize(record:, directory:)
      @record = record
      @directory = directory
    end

    def to_a
      layers = [{ label: "shape", copies: [{ cells: shape.cells, ring: 0 }] }]
      layers << { label: "tiling", copies: tiling } if tiling
      coronas.each { |depth, copies| layers << { label: "corona #{depth}", copies: } }
      layers
    end

    private

    attr_reader :directory, :record

    def shape = @shape ||= Census::Polycube.new(cells: record[:cells])

    # A chunk of the certified tiling, one copy per group. The copy sitting
    # on the seed keeps the seed's colour.
    def tiling
      certificate = record[:certificate]
      return nil unless certificate && %w[box torus].include?(certificate[:type])

      Census::Assembly.groups_for(certificate:, shape:).map.with_index do |group, index|
        { cells: group[:cells], ring: group[:cells].sort == shape.cells ? 0 : 1 + (index % 7) }
      end
    end

    # The deepest corona witness beside the record, shown cumulatively:
    # selecting corona 2 draws the seed, ring 1, and ring 2.
    def coronas
      witness = deepest_witness
      return [] unless witness

      rings = witness.keys.map { Integer(it.to_s) }.sort
      rings.each_with_object({}) do |depth, layers|
        copies = [{ cells: shape.cells, ring: 0 }]
        (1..depth).each do |ring|
          witness[ring.to_s.to_sym].each do |placement|
            copies << { cells: Census::Assembly.placed_cells(placement, shape), ring: }
          end
        end
        layers[depth] = copies
      end
    end

    # The deepest corona<k>.json beside the record. A depth-1 witness written
    # by the surround stage is a bare placement list, so it is read as ring 1.
    def deepest_witness
      path = Dir.glob(File.join(directory, "corona*.json")).max_by { it[/corona(\d+)/, 1].to_i }
      return nil unless path

      witness = JSON.parse(File.read(path), symbolize_names: true)
      witness.is_a?(Array) ? { "1": witness } : witness
    end
  end
end
