# frozen_string_literal: true

module Site
  # A listing cut into pages of a fixed size. Page 1 lives at the listing's
  # own path, later pages under page/N/, so /9/ is the nonacubes and
  # /9/page/2/ the next hundred.
  class Pagination
    PER_PAGE = 100

    Page = Struct.new(:number, :total, :rows, :path, :previous_path, :next_path, keyword_init: true)

    def initialize(entries:, base:, per_page: PER_PAGE)
      @entries = entries
      @base = base
      @per_page = per_page
    end

    def pages
      slices = @entries.each_slice(@per_page).to_a
      slices = [[]] if slices.empty?
      total = slices.size
      slices.each_with_index.map do |rows, position|
        number = position + 1
        Page.new(number:, total:, rows:, path: path_for(number),
                 previous_path: number > 1 ? path_for(number - 1) : nil,
                 next_path: number < total ? path_for(number + 1) : nil)
      end
    end

    def path_for(number) = number == 1 ? @base : "#{@base}page/#{number}/"
  end
end
