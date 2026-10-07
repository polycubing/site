# frozen_string_literal: true

module Site
  # The census as the site sees it: every record under data/, read one at a
  # time. Listings and counts keep only what a table row needs, so memory
  # stays flat whatever the size of the census.
  class Catalog
    Entry = Struct.new(:id, :cubes, :index, :nickname, :verdict, :badge, :how, :chiral, :tags, :path, keyword_init: true)

    def initialize(data:, names:, max_size: nil)
      @data = Pathname(data)
      @names = names
      @max_size = max_size
    end

    def sizes
      @sizes ||= @data.children.select(&:directory?).map { Integer(it.basename.to_s) }.select { @max_size.nil? || it <= @max_size }.sort
    end

    # Records of one size, in index order, each yielded once and not kept.
    def each_record(size)
      return enum_for(:each_record, size) unless block_given?

      @data.join(size.to_s).children.select(&:directory?).sort_by { Integer(it.basename.to_s) }.each do |directory|
        yield Record.new(directory: directory.to_s, names: @names)
      end
    end

    def entries
      @entries ||= sizes.flat_map do |size|
        each_record(size).map do |record|
          Entry.new(id: record.id, cubes: size, index: record.index, nickname: record.nickname, verdict: record.verdict,
                    badge: record.badge, how: record.how, chiral: record.chiral?, tags: record.tags, path: record.path)
        end
      end
    end

    def entries_of(size) = entries.select { it.cubes == size }

    def tagged(tag) = entries.select { it.tags.include?(tag) }

    # The scoreboard: per size, how many of each verdict.
    def counts
      sizes.map do |size|
        rows = entries_of(size)
        { size:, shapes: rows.size, tilers: rows.count { it.verdict == "tiler" },
          non_tilers: rows.count { it.verdict == "non_tiler" }, open: rows.count { it.verdict == "open" } }
      end
    end
  end
end
