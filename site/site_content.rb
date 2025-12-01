# frozen_string_literal: true

require 'open3'

class SiteContent
  attr_reader :readme_path, :index_path, :syntax_css_path

  def initialize()
    site_dir = File.expand_path('src', __dir__)
    @readme_path = File.expand_path('../README.md', __dir__)
    @index_path = File.join(site_dir, 'index.md')
    @syntax_css_path = File.join(site_dir, 'assets/css/syntax.css')
  end

  def filter_readme
    (filter_readme_lines + ['']).join("\n")
  end

  # Write index.md file.
  def write_index
    File.write(index_path, generate_front_matter + filter_readme)
  end

  # Write syntax.css file.
  def generate_syntax_css
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rougify', 'style', 'github.light')
    raise "rougify failed:\n#{stderr}" unless status.success?

    File.write(syntax_css_path, stdout)
  end

  private

  def generate_front_matter
    <<~FRONT
      ---
      layout: default
      ---

    FRONT
  end

  def filter_readme_lines
    lines = File.readlines(readme_path, chomp: true)
    filtered = []
    skip_plugin_section = false
    skip_amendments_section = false

    lines.each do |line|
      # Exclude the SPM command plugin section from the site.
      if line.start_with?('## Swift Package Manager command plugin')
        skip_plugin_section = true
        next
      elsif skip_plugin_section
        skip_plugin_section = false if line.start_with?('## ')
        next if skip_plugin_section
      end

      if line.start_with?('## Amendments')
        skip_amendments_section = true
        next
      elsif skip_amendments_section
        skip_amendments_section = false if line.start_with?('** ')
        next if skip_amendments_section
      end

      # Exclude the badges from the site.
      stripped = line.strip
      next if stripped.start_with?('[![](') && stripped.include?('swiftpackageindex.com')

      filtered << line.rstrip
    end

    filtered
  end
end
