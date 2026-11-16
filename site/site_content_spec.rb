# frozen_string_literal: true

require_relative 'site_content'

# Basic integration tests for `site_content.rb`,
# validating the high level structure of the content.
RSpec.describe SiteContent do
  subject(:site_content) { described_class.new }

  describe 'README.md' do
    let(:readme_content) { File.read(site_content.readme_path) }

    # Relative file URLs resolve differently on github.com/airbnb/swift vs swift.airbnb.tech
    it 'does not use relative URLs' do
      # Match markdown links that don't start with # or http(s)
      relative_links = readme_content.scan(/\]\((?!#|https?:)([^)]+)\)/).flatten
      expect(relative_links).to be_empty, "Found relative links: #{relative_links.join(', ')}"
    end

    it 'has all rule descriptions include a bolded portion' do
      rule_lines = readme_content.lines.map(&:chomp).select { |line| line.match?(/^- <a id='/) }
      rules_without_bold = rule_lines.reject { |line| line.include?('**') }
      expect(rules_without_bold).to be_empty,
        "Found rule descriptions without bold text:\n#{rules_without_bold.join("\n")}"
    end
  end

  describe 'index.md' do
    let(:index_content) { site_content.index_content }

    it 'has at least 9 ## sections' do
      section_count = index_content.scan(/^## /).count
      expect(section_count).to be >= 9
    end

    it 'has at least 3 ### subsections' do
      subsection_count = index_content.scan(/^### /).count
      expect(subsection_count).to be >= 3
    end

    it 'includes <details> blocks' do
      expect(index_content).to include('<details>')
    end

    it 'does not include command plugin section' do
      expect(index_content).not_to include('command plugin')
    end

    it 'includes Table of Contents section' do
      expect(index_content).to include('## Table of Contents')
    end

    it 'has the expected ordered list of markdown headers' do
      headers = index_content.lines.map(&:chomp).grep(/^#+ /)
      expect(headers).to eq [
        '# Airbnb Swift Style Guide',
        '## Goals',
        '## Guiding Tenets',
        '## Table of Contents',
        '## Xcode Formatting',
        '## Naming',
        '## Style',
        '### Functions',
        '### Closures',
        '### Operators',
        '## Patterns',
        '## File Organization',
        '## SwiftUI',
        '## Testing',
        '## Performance',
        '## Apple Frameworks',
      ]
    end

    it 'has no invalid anchor links' do
      # Extract all anchor links of the form [text](#anchor-name)
      anchor_links = index_content.scan(/\[.*?\]\(#([^)]+)\)/).flatten

      # Extract all markdown headers and convert to anchor format
      # Headers like "## Xcode Formatting" become "xcode-formatting"
      header_anchors = index_content.scan(/^##+ (.+)$/).flatten.map do |header|
        header
          .downcase
          .gsub(/[^\w\s-]/, '') # Remove special characters except hyphens
          .gsub(/\s+/, '-') # Replace spaces with hyphens
          .gsub(/-+/, '-') # Collapse multiple hyphens
          .gsub(/^-|-$/, '') # Remove leading/trailing hyphens
      end

      # Extract HTML anchor IDs of the form <a id='anchor-name'>
      html_anchors = index_content.scan(/<a id=['"]([^'"]+)['"]>/).flatten

      all_anchors = header_anchors + html_anchors

      missing_anchors = anchor_links.reject { |anchor| all_anchors.include?(anchor) }

      expect(missing_anchors).to be_empty,
        "Found anchor links with no corresponding header: #{missing_anchors.join(', ')}"
    end
  end

  describe 'SKILL.md' do
    let(:skill_content) { site_content.skill_md_content }
    let(:readme_content) { File.read(site_content.readme_path) }

    it 'includes valid skill frontmatter with a name and description' do
      frontmatter = YAML.safe_load(skill_content.split('---', 3)[1])
      expect(frontmatter).to eq(
        'name' => 'swift', 'description' => 'Always use when creating and editing Swift files (*.swift)')
    end

    it 'has at least 5 ## sections' do
      section_count = skill_content.scan(/^## /).count
      expect(section_count).to be >= 5
    end

    it 'has at least 1 ### subsection' do
      subsection_count = skill_content.scan(/^### /).count
      expect(subsection_count).to be >= 1
    end

    it 'does not include <details> blocks' do
      expect(skill_content).not_to include('<details>')
      expect(readme_content).to include('<details>')
    end

    it 'does not include img.shields.io badges' do
      expect(skill_content).not_to include('img.shields.io')
      expect(readme_content).to include('img.shields.io')
    end

    it 'does not include command plugin section' do
      expect(skill_content).not_to include('command plugin')
      expect(readme_content).to include('command plugin')
    end

    it 'does not include Table of Contents section' do
      expect(skill_content).not_to include('Table of Contents')
      expect(readme_content).to include('Table of Contents')
    end

    it 'does not include Goals section' do
      expect(skill_content).not_to include('## Goals')
      expect(readme_content).to include('## Goals')
    end

    it 'does not include Guiding Tenets section' do
      expect(skill_content).not_to include('## Guiding Tenets')
      expect(readme_content).to include('## Guiding Tenets')
    end

    it 'does not include Markdown link destinations' do
      expect(skill_content).not_to match(/\[([^\]]+)\]\(([^)]+)\)/)
    end

    it 'identifies every summary with a bracketed rule ID' do
      summaries = skill_content.lines.grep(/^\[/)
      expect(summaries).not_to be_empty
      expect(skill_content).not_to match(/^[-*] /)
      summaries.each do |line|
        expect(line).to match(/^\[([^\]]+)\] /)
        expect(site_content.rule_contents).to have_key(line[/^\[([^\]]+)\]/, 1])
      end
    end

    it 'explains when and how to load the full guidance' do
      expect(skill_content).to include('`[rule-id]`, referring to `rules/<rule-id>.md` relative to this file')
      expect(skill_content).to include('Read the relevant rule files')
      expect(skill_content).to include('Load only the rules needed for the current task')
    end

    it 'introduces the style guide in one sentence before the rule ID instructions' do
      introduction = skill_content.split("\n\n").find { |paragraph| paragraph.start_with?('The Airbnb Swift Style Guide') }
      expect(introduction).to match(/\A[^\n.]+\.\z/)
      expect(skill_content.index(introduction)).to be < skill_content.index('Each rule summary')
    end

    it 'keeps the rule loading instructions in one paragraph without hard line breaks' do
      paragraph = skill_content.split("\n\n").find { |text| text.start_with?('Read the relevant rule files') }
      expect(paragraph).to include('full explanation, examples, and exceptions.')
      expect(paragraph).not_to include("\n")
    end

    it 'does not include HTML anchor tags' do
      expect(skill_content).not_to include('<a')
      expect(readme_content).to include('<a')
    end

    it 'includes rules with autocorrect that have ai-skill-include' do
      # The 'prefer for loops' rule has both a SwiftFormat badge and <!-- ai-skill-include -->,
      # so it should be included in SKILL.md despite having autocorrect
      expect(skill_content).to include('Prefer using `for` loops')
    end

    it 'does not include rules that are fully autocorrected' do
      # The 'indent' rule is fully autocorrected by SwiftFormat,
      # so it should be excluded from SKILL.md
      expect(skill_content).not_to include('Use 2 spaces to indent lines')
      expect(readme_content).to include('Use 2 spaces to indent lines')
    end

    it 'does not include empty sections' do
      # Find sections that are immediately followed by another section (no content between them)
      empty_sections = skill_content.scan(/^(## .+)\n+(?=## )/).flatten
      expect(empty_sections).to be_empty,
        "Found empty sections: #{empty_sections.join(', ')}"
    end

    it 'removes backticks from inline code ending with !' do
      # Inline code like `try!` can be interpreted as a bash command, so we remove the backticks
      expect(readme_content).to include('`try!`')
      expect(skill_content).not_to include('!`')
    end
  end

  describe 'full rule content' do
    let(:rules) { site_content.rule_contents }

    it 'includes exactly one entry per rule, including rules omitted from the summary' do
      ids = File.read(site_content.readme_path).scan(/^[-*] <a id=['"]([^'"]+)['"]>/).flatten
      expect(rules.keys).to eq(ids)
      expect(rules).to have_key('spaces-over-tabs')
      expect(rules).to have_key('cifilter-builtins')
      expect(rules).to have_key('prefer-for-loop-over-forEach')
    end

    it 'retains explanations, examples, and external links' do
      content = rules.fetch('swift-testing-test-case-names')
      expect(content).to include('**In Swift Testing, name test cases')
      expect(content).to include('### Why?', 'Raw identifiers with spaces are easier to read')
      expect(content).to include('```swift', 'func `warp drive enables FTL travel`() { ... }')
      expect(content).to include('https://github.com/swiftlang/swift-evolution/blob/main/proposals/0451-escaped-identifiers.md')
      expect(content).not_to include('redundant-swift-testing-suite-macro')
    end

    it 'retains exceptions and code indentation' do
      content = rules.fetch('use-camel-case')
      expect(content).to include('_Exception: You may prefix a private property')
      expect(content).to include("```swift\nprotocol SpaceThing {\n  ...\n}")
      expect(content).to include('private lazy var _view = CustomView()')
    end

    it 'makes style guide anchor links usable outside the main guide' do
      expect(rules.fetch('long-typealias')).to include('[Long](https://swift.airbnb.tech/#column-width)')
      rules.each_value do |content|
        expect(content).not_to match(/\]\(#[^)]+\)/)
      end
    end

    it 'removes list navigation, disclosure wrappers, and generator directives' do
      rules.each_value do |content|
        expect(content).not_to include('⬆ back to top', '<details>', '</details>', 'ai-skill-include', 'img.shields.io')
        expect(content).not_to match(/^[-*] <a id=/)
        expect(content).to end_with("\n")
      end
    end
  end
end
