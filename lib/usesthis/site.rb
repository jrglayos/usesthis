# frozen_string_literal: true

module UsesThis
  # A class that generates the usesthis.com site.
  class Site < Dimples::Site
    attr_accessor :hardware
    attr_accessor :software
    attr_accessor :links
    attr_accessor :stats

    def initialize(config = {})
      super

      @hardware = {}
      @software = {}

      @links = {
        inspired: [],
        personal: [],
        sponsor: []
      }

      @source_paths[:wares] = File.join(@source_paths[:root], 'gear')
      @source_paths[:links] = File.join(@source_paths[:root], 'links')
    end

    def scan_files
      scan_gear
      scan_links

      super
    end

    def scan_gear
      %w[hardware software].each do |type|
        type_path = File.join(@source_paths[:wares], type, '**', '*.yml')
        Dir.glob(type_path).each do |path|
          ware = case type
                 when 'hardware'
                   UsesThis::Hardware.new(path)
                 when 'software'
                   UsesThis::Software.new(path)
                 end

          send(type)[ware.slug] = ware
        end
      end
    end

    def scan_links
      %w[inspired personal sponsor].each do |type|
        Dir.glob(File.join(@source_paths[:links], type, '*.yml')).each do |path|
          @links[type.to_sym] << UsesThis::Link.new(path)
        end
      end
    end

    def generate_files
      super
      UsesThis::API.generate(self)
    end

    def generate_posts
      super

      errors_path = File.join(@source_paths[:root], 'errors', '*.markdown')

      Dir.glob(errors_path) do |path|
        page = @post_class.new(self, path)

        page.filename = File.basename(path, '.markdown')
        page.layout = 'interview'

        page.write(File.join(@output_paths[:site], "#{page.slug}.html"))
      end
    end
  end
end
