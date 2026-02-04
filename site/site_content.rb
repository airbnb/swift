# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'set'

class SiteContent
  attr_reader :readme_path, :index_path, :skill_md_path, :skill_md_raw_path, :syntax_css_path

  def initialize()
    site_dir = File.expand_path('src', __dir__)
    @syntax_css_path = File.join(site_dir, 'assets/css/syntax.css')
    @readme_path = File.expand_path('../README.md', __dir__)
    @index_path = File.join(site_dir, 'index.md')
    @skill_md_path = File.join(site_dir, 'SKILL.md')
    @skill_md_raw_path = File.join(site_dir, 'raw', 'SKILL.md')
  end
  
  # Write index.md file (https://airbnb.swift.tech)
  def write_index
    front_matter = <<~FRONT
      ---
      layout: default
      ---

    FRONT
    File.write(index_path, front_matter + index_content)
  end

  def index_content
    filter_readme(
      filter_goals: false,
      filter_guiding_tenets: false,
      filter_spm_plugin: true,
      filter_table_of_contents: false,
      filter_xcode_formatting: false,
      filter_contributors: true,
      filter_amendments: true,
      filter_rule_details: false,
      filter_autocorrectable_rules: false
    )
  end

  # Write SKILL.md file (https://airbnb.swift.tech/SKILL.md)
  def write_skill_md
    front_matter = <<~FRONT
      ---
      layout: default
      permalink: /SKILL.md
      ---

    FRONT
    header = <<~HEADER
      # SKILL.md

      AI skill for working with Swift code.

      Summarizes the Airbnb Swift Style Guide, but excludes rules that are enforced automatically with formatting or linting.

      Raw `SKILL.md` can be downloaded [here](/raw/SKILL.md).

    HEADER
    wrapped_content = "#{header}````markdown\n#{skill_md_content}\n````\n"
    File.write(skill_md_path, front_matter + wrapped_content)
  end

  # Write raw SKILL.md file (https://airbnb.swift.tech/SKILL.md.raw)
  def write_skill_md_raw
    FileUtils.mkdir_p(File.dirname(skill_md_raw_path))
    jekyll_front_matter = <<~FRONT
      ---
      layout: raw
      permalink: /raw/SKILL.md
      ---
    FRONT
    File.write(skill_md_raw_path, jekyll_front_matter + skill_md_content)
  end

  def skill_md_content
    frontmatter = <<~FRONT
      ---
      name: swift
      description: Always use when creating and editing Swift files (*.swift)
      ---

    FRONT
    frontmatter + filter_readme(
      filter_goals: true,
      filter_guiding_tenets: true,
      filter_spm_plugin: true,
      filter_table_of_contents: true,
      filter_xcode_formatting: true,
      filter_contributors: true,
      filter_amendments: true,
      filter_rule_details: true,
      filter_autocorrectable_rules: true
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
    filter_rule_details:,
    filter_autocorrectable_rules:
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
    lines = filter_autocorrectable_rules(lines) if filter_autocorrectable_rules
    lines = filter_empty_sections(lines)
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

  def filter_empty_sections(lines)
    # First pass: identify which sections/subsections have rules
    sections_with_rules = Set.new
    current_section_start = nil
    current_subsection_start = nil

    lines.each_with_index do |line, index|
      if line.start_with?('## ')
        current_section_start = index
        current_subsection_start = nil
      elsif line.start_with?('### ')
        current_subsection_start = index
      elsif line.start_with?('- ')
        sections_with_rules.add(current_section_start) if current_section_start
        sections_with_rules.add(current_subsection_start) if current_subsection_start
      end
    end

    # Second pass: filter out empty sections/subsections
    filtered = []
    skip_until_next_section = false

    lines.each_with_index do |line, index|
      if line.start_with?('## ') || line.start_with?('### ')
        skip_until_next_section = !sections_with_rules.include?(index)
      end

      filtered << line unless skip_until_next_section
    end

    filtered
  end

  def filter_autocorrectable_rules(lines)
    # First pass: identify which rules have SwiftFormat/SwiftLint badges and/or <!-- ai-skill-include -->
    rules_with_badges = Set.new
    rules_with_include = Set.new
    current_rule_start = nil

    lines.each_with_index do |line, index|
      if line.start_with?('- ')
        current_rule_start = index
      elsif current_rule_start
        if line.include?('img.shields.io/badge/SwiftFormat') || line.include?('img.shields.io/badge/SwiftLint')
          rules_with_badges.add(current_rule_start)
        end
        if line.include?('<!-- ai-skill-include -->')
          rules_with_include.add(current_rule_start)
        end
      end
      if line.start_with?('## ') || line.start_with?('**[')
        current_rule_start = nil
      end
    end

    # Second pass: filter out rules with badges unless they have <!-- ai-skill-include -->
    filtered = []
    skip_until_next_rule = false

    lines.each_with_index do |line, index|
      if line.start_with?('- ')
        has_badge = rules_with_badges.include?(index)
        has_include = rules_with_include.include?(index)
        skip_until_next_rule = has_badge && !has_include
      elsif line.start_with?('## ') || line.start_with?('**[')
        skip_until_next_rule = false
      end

      filtered << line unless skip_until_next_rule
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

      # Remove markdown links, keeping just the link text (but not image links like [![](img)](url))
      line = line.gsub(/\[(?!\!\[)([^\]]+)\]\([^)]+\)/, '\1')

      filtered << line
    end

    filtered
  end
end
