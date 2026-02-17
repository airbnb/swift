# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'set'

class SiteContent
  attr_reader :readme_path, :index_path, :ai_skill_page_path, :ai_skill_raw_path, :syntax_css_path

  def initialize()
    site_dir = File.expand_path('src', __dir__)
    @syntax_css_path = File.join(site_dir, 'assets/css/syntax.css')
    @readme_path = File.expand_path('../README.md', __dir__)
    @index_path = File.join(site_dir, 'index.md')
    @ai_skill_page_path = File.join(site_dir, 'ai-skill.md')
    @ai_skill_raw_path = File.join(site_dir, 'SKILL.md')
  end
  
  # Write index.md file (https://airbnb.swift.tech)
  def write_index
    front_matter = <<~FRONT
      ---
      layout: default
      title: Airbnb Swift Style Guide
      description: Airbnb's Swift Style Guide. Over 100 style rules spanning basic syntax, code organization, patterns, SwiftUI, testing, and other best practices.
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
      filter_autocorrectable_rules: false,
      filter_links: false
    )
  end

  # Write skill page (https://airbnb.swift.tech/skill)
  def write_skill_md
    front_matter = <<~FRONT
      ---
      layout: default
      permalink: /skill
      title: Airbnb Swift AI Skill
      description: AI skill for working with Swift code. Summarizes the Airbnb Swift Style Guide.
      ---

    FRONT
    header = <<~HEADER
      # SKILL.md

      AI skill for working with Swift code.

      Summarizes the Airbnb Swift Style Guide, but excludes rules that are automatically enforced with code formatting.

      Raw `SKILL.md` can be downloaded [here](/SKILL.md).

    HEADER
    wrapped_content = "#{header}````markdown\n#{skill_md_content}\n````\n"
    File.write(ai_skill_page_path, front_matter + wrapped_content)
  end

  # Write raw SKILL.md file (https://airbnb.swift.tech/SKILL.md)
  def write_skill_md_raw
    jekyll_front_matter = <<~FRONT
      ---
      layout: raw
      permalink: /SKILL.md
      ---
    FRONT
    File.write(ai_skill_raw_path, jekyll_front_matter + skill_md_content)
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
      filter_autocorrectable_rules: true,
      filter_links: true
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
    filter_autocorrectable_rules:,
    filter_links:
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
    lines = filter_details_blocks(lines) if filter_rule_details
    lines = filter_links(lines) if filter_links
    lines = filter_empty_sections(lines)

    # Exclude the badges from the site.
    lines = lines.reject do |line|
      stripped = line.strip
      stripped.start_with?('[![](') && stripped.include?('swiftpackageindex.com')
    end

    # Exclude Contributors and Amendments from the Table of Contents.
    lines = lines.reject do |line|
      (filter_contributors && line.include?('[Contributors](#contributors)')) ||
        (filter_amendments && line.include?('[Amendments](#amendments)'))
    end

    lines = lines.map(&:rstrip)

    content = (lines + ['']).join("\n")

    # Remove consecutive blank lines (max 1 in a row)
    content = content.gsub(/\n{3,}/, "\n\n")

    # Remove backticks from inline code ending with ! (e.g. `try!`) to prevent shell command interpretation
    # https://github.com/anthropics/claude-code/issues/12762#issuecomment-3830966564
    content.gsub(/`([^`]*!)`/, '\1')
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
    # First pass: identify which sections/subsections have content
    sections_with_content = Set.new
    current_section_start = nil
    current_subsection_start = nil

    lines.each_with_index do |line, index|
      if line.start_with?('## ')
        current_section_start = index
        current_subsection_start = nil
      elsif line.start_with?('### ')
        current_subsection_start = index
      elsif !line.strip.empty?
        sections_with_content.add(current_section_start) if current_section_start
        sections_with_content.add(current_subsection_start) if current_subsection_start
      end
    end

    # Second pass: filter out empty sections/subsections
    filtered = []
    skip_until_next_section = false

    lines.each_with_index do |line, index|
      if line.start_with?('## ') || line.start_with?('### ')
        skip_until_next_section = !sections_with_content.include?(index)
      end

      filtered << line unless skip_until_next_section
    end

    filtered
  end

  def filter_autocorrectable_rules(lines)
    # First pass: identify which rules have SwiftFormat badges and/or <!-- ai-skill-include -->
    rules_with_badges = Set.new
    rules_with_include = Set.new
    current_rule_start = nil

    lines.each_with_index do |line, index|
      if line.start_with?('- ')
        current_rule_start = index
      elsif current_rule_start
        if line.include?('img.shields.io/badge/SwiftFormat')
          rules_with_badges.add(current_rule_start)
        end

        # Match <!-- ai-skill-include --> or <!-- ai-skill-include: explanation -->
        if line.match?(/<!-- ai-skill-include(:.*)? -->/)
          rules_with_include.add(current_rule_start)
        end
      end
      if line.start_with?('## ') || line.include?('⬆ back to top')
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
      elsif line.start_with?('## ') || line.include?('⬆ back to top')
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

      # Remove bold/italic markers
      line = line.gsub('**', '')

      filtered << line
    end

    filtered
  end

  def filter_links(lines)
    lines.map do |line|
      # Remove image-link badges like [![](img)](url)
      line = line.gsub(/\[!\[[^\]]*\]\([^)]*\)\]\([^)]*\)/, '')

      # Remove markdown links, keeping just the link text
      line = line.gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')

      # Remove any anchor tags
      line.gsub(/<a id='[^']*'><\/a> ?/, '')
    end
  end
end
