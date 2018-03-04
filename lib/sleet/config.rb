# frozen_string_literal: true

module Sleet
  class Config
    OPTION_FILENAME = '.sleet.yml'
    ConfigOption = Struct.new(:value, :source)

    def initialize(dir:, cli_hash: {})
      @dir = dir
      @cli_hash = cli_hash
    end

    def options_hash
      Thor::CoreExt::HashWithIndifferentAccess.new(options.map { |k, o| [k, o.value] }.to_h)
    end

    def options
      default_options.merge(file_options).merge(cli_options)
    end

    def print!
      puts Terminal::Table.new headings: %w[Option Value Source], rows: table_rows
    end

    private

    attr_reader :cli_hash, :dir

    def table_rows
      options.map do |key, option|
        if key.to_sym == :workflows
          [key, Terminal::Table.new(headings: ['Job Name', 'Output File'], rows: option.value.to_a), option.source]
        else
          [key, option.value, option.source]
        end
      end
    end

    def cli_options
      build_option_hash('CLI', cli_hash)
    end

    def file_options
      file_hashes.map do |file, options|
        build_option_hash(file, options)
      end.reduce({}, :merge)
    end

    def file_hashes
      files.map { |f| [f, ::YAML.load_file(f) || {}] }
    end

    def files
      paths_to_search.select { |f| File.file?(f) }
    end

    def paths_to_search
      directories.each_index.map do |i|
        (directories[0..i] + [OPTION_FILENAME]).join('/')
      end
    end

    def directories
      @_directories ||= dir.split('/')
    end

    def default_options
      build_option_hash 'default', default_hash
    end

    def default_hash
      {
        'source_dir' => File.expand_path(default_dir),
        'input_file' => '.rspec_example_statuses',
        'output_file' => '.rspec_example_statuses'
      }
    end

    def default_dir
      Rugged::Repository.discover(Dir.pwd).path + '..'
    rescue Rugged::RepositoryError
      '.'
    end

    def build_option_hash(source, options)
      options.map do |key, value|
        [key, ConfigOption.new(value, source)]
      end.to_h
    end
  end
end
