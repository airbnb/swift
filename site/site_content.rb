# frozen_string_literal: true

require 'fileutils'
require 'open3'

class SiteContent
  attr_reader :readme_path, :index_path, :claude_md_path, :claude_md_raw_path, :syntax_css_path

  def initialize()
    site_dir = File.expand_path('src', __dir__)
    @readme_path = File.expand_path('../README.md', __dir__)
    @index_path = File.join(site_dir, 'index.md')
    @claude_md_path = File.join(site_dir, 'CLAUDE.md')
    @claude_md_raw_path = File.join(site_dir, 'raw', 'CLAUDE.md')
    @syntax_css_path = File.join(site_dir, 'assets/css/syntax.css')
  end
  
  # Write index.md file (https://airbnb.swift.tech)
  def write_index
    front_matter = <<~FRONT
      ---
      layout: default
      ---

    FRONT
    content = filter_readme(
      filter_goals: false,
      filter_guiding_tenets: false,
      filter_spm_plugin: true,
      filter_table_of_contents: false,
      filter_xcode_formatting: false,
      filter_contributors: true,
      filter_amendments: true,
      filter_rule_details: false
    )
    File.write(index_path, front_matter + content)
  end

  # Write CLAUDE.md file (https://airbnb.swift.tech/CLAUDE.md)
  def write_claude_md
    front_matter = <<~FRONT
      ---
      layout: default
      permalink: /CLAUDE.md
      ---

    FRONT
    header = <<~HEADER
      # CLAUDE.md

      CLAUDE.md file that summarizes the Airbnb Swift Style Guide.

      Raw CLAUDE.md can be downloaded [here](/raw/CLAUDE.md).

    HEADER
    wrapped_content = "#{header}````markdown\n#{claude_md_content}\n````\n"
    File.write(claude_md_path, front_matter + wrapped_content)
  end

  # Write raw CLAUDE.md file (https://airbnb.swift.tech/raw/CLAUDE.md)
  def write_claude_md_raw
    FileUtils.mkdir_p(File.dirname(claude_md_raw_path))
    File.write(claude_md_raw_path, claude_md_content)
  end

  def claude_md_content
    filter_readme(
      filter_goals: true,
      filter_guiding_tenets: true,
      filter_spm_plugin: true,
      filter_table_of_contents: true,
      filter_xcode_formatting: true,
      filter_contributors: true,
      filter_amendments: true,
      filter_rule_details: true
    )
  end

  # Write syntax.css file.
  def generate_syntax_css
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rougify', 'style', 'github.light')
    raise "rougify failed:\n#{stderr}" unless status.success?

    File.write(syntax_css_path, stdout)
  end

  private

  # Process the README.md by filtering out the given content
  def filter_readme(
    filter_goals:,
    filter_guiding_tenets:,
    filter_spm_plugin:,
    filter_table_of_contents:,
    filter_xcode_formatting:,
    filter_contributors:,
    filter_amendments:,
    filter_rule_details:
  )
    lines = File.readlines(readme_path, chomp: true)

    sections_to_filter = []
    sections_to_filter << 'Goals' if filter_goals
    sections_to_filter << 'Guiding Tenets' if filter_guiding_tenets
    sections_to_filter << 'Swift Package Manager command plugin' if filter_spm_plugin
    sections_to_filter << 'Table of Contents' if filter_table_of_contents
    sections_to_filter << 'Xcode Formatting' if filter_xcode_formatting
    sections_to_filter << 'Contributors' if filter_contributors
    sections_to_filter << 'Amendments' if filter_amendments

    lines = filter_sections(lines, sections_to_filter)
    lines = filter_details_blocks(lines) if filter_rule_details

    # Exclude the badges from the site.
    lines = lines.reject do |line|
      stripped = line.strip
      stripped.start_with?('[![](') && stripped.include?('swiftpackageindex.com')
    end.map(&:rstrip)

    content = (lines + ['']).join("\n")

    # Remove consecutive blank lines (max 1 in a row)
    content.gsub(/\n{3,}/, "\n\n")
  end

  def filter_sections(lines, section_names)
    return lines if section_names.empty?

    filtered = []
    skip_current_section = false

    lines.each do |line|
      if line.start_with?('## ')
        section_title = line.sub(/^## /, '')
        skip_current_section = section_names.include?(section_title)
      end

      filtered << line unless skip_current_section
    end

    filtered
  end

  def filter_details_blocks(lines)
    filtered = []
    inside_details = false

    lines.each do |line|
      if line.strip.start_with?('<details')
        inside_details = true
        next
      elsif line.strip == '</details>'
        inside_details = false
        next
      end

      next if inside_details

      # Skip "back to top" lines
      next if line.strip == '**[⬆ back to top](#table-of-contents)**'

      # Remove (link) anchors from lines
      line = line.gsub(/<a id='[^']*'><\/a> ?\(?<a href='[^']*'>link<\/a>\)? ?/, '')
      # Remove any remaining standalone anchors
      line = line.gsub(/<a id='[^']*'><\/a> ?/, '')

      # Remove bold/italic markers
      line = line.gsub('**', '')

      filtered << line
    end

    filtered
  end
end
