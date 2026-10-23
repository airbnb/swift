# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'set'
require 'rouge'
require 'yaml'

class SiteContent
  attr_reader :readme_path, :index_path, :ai_skill_page_path, :ai_skill_raw_path, :syntax_css_path,
    :skill_dir, :skill_pages_dir, :skill_zip_path

  def initialize(site_dir: File.expand_path('src', __dir__),
    skill_dir: File.expand_path('swift', __dir__), readme_path: File.expand_path('../README.md', __dir__))
    @syntax_css_path = File.join(site_dir, 'assets/css/syntax.css')
    @readme_path = readme_path
    @index_path = File.join(site_dir, 'index.md')
    @ai_skill_page_path = File.join(site_dir, 'ai-skill.md')
    @ai_skill_raw_path = File.join(site_dir, 'SKILL.md')
    @skill_dir = skill_dir
    @skill_pages_dir = File.join(site_dir, 'skill')
    @skill_zip_path = File.join(site_dir, 'skills', 'swift.zip')
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
      filter_ai_skill: true,
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
      # Airbnb Swift AI Skill

      AI skill for working with Swift code.

      The main file summarizes rules that are not fully enforced by code formatting. Individual rule files include the full guidance from the Airbnb Swift Style Guide.

      Download: [skills/swift.zip](/skills/swift.zip)

    HEADER
    rule_ids = rule_contents.keys.to_set
    highlighted_content = Rouge.highlight(skill_md_content, 'markdown', 'html')
    highlighted_content = highlighted_content.gsub(/\[([A-Za-z0-9_-]+)\]/) do |reference|
      id = Regexp.last_match(1)
      rule_ids.include?(id) ? %([<a href="/skill/#{id}">#{id}</a>]) : reference
    end
    wrapped_content = <<~HTML
      #{header}{% raw %}
      <div class="language-markdown highlighter-rouge"><div class="highlight">
      <pre class="highlight skill-preview"><code>#{highlighted_content}</code></pre>
      </div></div>
      {% endraw %}
    HTML
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
    content = filter_readme(
      filter_goals: true,
      filter_guiding_tenets: true,
      filter_spm_plugin: true,
      filter_ai_skill: true,
      filter_table_of_contents: true,
      filter_xcode_formatting: true,
      filter_contributors: true,
      filter_amendments: true,
      filter_rule_details: true,
      filter_autocorrectable_rules: true,
      filter_links: true
    )
    instructions = <<~TEXT
      The Airbnb Swift Style Guide defines conventions and best practices for writing clear, consistent Swift code.

      Each rule summary starts with `[rule-id]`, referring to `rules/<rule-id>.md` relative to this file.

      Read the relevant rule files when applying or reviewing a rule to load its full explanation, examples, and exceptions.

      Load only the rules needed for the current task. The `rules/` directory also includes rules that are omitted from this summary because they are automatically enforced by code formatting.
    TEXT
    frontmatter + content.sub("# Airbnb Swift Style Guide\n", "# Airbnb Swift Style Guide\n\n#{instructions}")
  end

  def rule_contents
    rules = {}
    current_id = nil

    File.foreach(readme_path) do |line|
      id = rule_id(line)
      if id
        raise "Duplicate rule ID: #{id}" if rules.key?(id)

        current_id = id
        rules[id] = [rule_description(line)]
      elsif line.match?(/^\#{2,3} /) || line.include?('⬆ back to top')
        current_id = nil
      elsif current_id
        rules[current_id] << line.sub(/^  /, '').rstrip
      end
    end

    rules.transform_values do |lines|
      lines = lines.reject { |line| line.strip.match?(/\A(?:<\/?details>|<!-- ai-skill-include.* -->)\z/) }
      lines = lines.map do |line|
        line.gsub(/\[!\[[^\]]*\]\(https?:\/\/img\.shields\.io\/[^)]*\)\]\([^)]+\)/, '')
      end
      content = lines.join("\n").strip.gsub(/\n{3,}/, "\n\n")
      content.gsub(/\]\(#([^)]+)\)/, '](https://swift.airbnb.tech/#\1)') + "\n"
    end
  end

  def write_skill_bundle
    FileUtils.mkdir_p(skill_dir)
    rules_dir = File.join(skill_dir, 'rules')
    FileUtils.rm_rf(rules_dir)
    FileUtils.mkdir_p(rules_dir)
    File.write(File.join(skill_dir, 'SKILL.md'), skill_md_content)
    rule_contents.each do |id, content|
      File.write(File.join(rules_dir, "#{id}.md"), "# #{id}\n\n#{content}")
    end

    # Recreate the archive so removed rules are not retained by zip's update behavior.
    FileUtils.mkdir_p(File.dirname(skill_zip_path))
    FileUtils.rm_f(skill_zip_path)
    archive_dir = File.basename(skill_dir)
    stdout, stderr, status = Open3.capture3('zip', '-q', '-r', skill_zip_path,
      "#{archive_dir}/SKILL.md", "#{archive_dir}/rules",
      chdir: File.dirname(skill_dir))
    raise "zip failed:\n#{stdout}#{stderr}" unless status.success?
  end

  def write_skill_rule_pages
    FileUtils.rm_rf(skill_pages_dir)
    FileUtils.mkdir_p(skill_pages_dir)
    rule_contents.each do |id, content|
      front_matter = {
        'layout' => 'default',
        'permalink' => "/skill/#{id}",
        'title' => "#{id} · Airbnb Swift AI Skill",
        'description' => "Full guidance for the #{id} rule in the Airbnb Swift Style Guide."
      }.to_yaml + "---\n\n"
      body = "[← Swift AI Skill](/skill)\n\n# #{id}\n\n#{content}"
      File.write(File.join(skill_pages_dir, "#{id}.md"), front_matter + "{% raw %}\n#{body}{% endraw %}\n")
    end
  end

  # Write syntax.css file.
  def generate_syntax_css
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rougify', 'style', 'github.light')
    raise "rougify failed:\n#{stderr}" unless status.success?

    File.write(syntax_css_path, stdout)
  end

  private

  def rule_id(line)
    line[/\A[-*] <a id=['"]([A-Za-z0-9_-]+)['"]><\/a>/, 1]
  end

  def rule_description(line)
    line.sub(/\A[-*] (?:<a id=['"][^'"]+['"]><\/a>\s*)+\(<a href=['"][^'"]+['"]>link<\/a>\)\s*/, '').rstrip
  end

  # Process the README.md by filtering out the given content
  def filter_readme(
    filter_goals:,
    filter_guiding_tenets:,
    filter_spm_plugin:,
    filter_ai_skill:,
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
    sections_to_filter << 'AI Skill' if filter_ai_skill
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

    # Exclude the swift.airbnb.tech URL line from the site.
    lines = lines.reject { |line| line.strip == 'https://swift.airbnb.tech' }

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
      if rule_id(line)
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
      if rule_id(line)
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

      if (id = rule_id(line))
        line = "[#{id}] #{rule_description(line)}"
      end

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
