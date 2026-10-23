# frozen_string_literal: true

require_relative 'site_content'
require 'tmpdir'
require 'cgi'
require 'jekyll'

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

  describe 'generation with a small style guide' do
    let(:readme) do
      <<~MARKDOWN
        # Airbnb Swift Style Guide

        ## Goals

        Goal text.

        ## Naming

        - <a id='plain-rule'></a>(<a href='#plain-rule'>link</a>) **Use clear names.**

          <details>

          #### Why?

          Preserve the explanation, [other rule](#mixedCase-rule), and [section](#naming).

          ```swift
          let value = "<tag> & {{ template }}"
          if value.isEmpty {
            print(value)
          }
          ```

          _Exception: Keep meaningful abbreviations._

          </details>

        - <a id='brief-rule'></a>(<a href='#brief-rule'>link</a>) **A rule without details.**

        ### Functions

        * <a id="mixedCase-rule"></a>(<a href="#mixedCase-rule">link</a>) **A starred rule.**

          <details>

          Starred rule explanation.

          </details>

        * <a id='autocorrected-rule'></a>(<a href='#autocorrected-rule'>link</a>) **Omit this summary.**

          <details>

          [![SwiftFormat](https://img.shields.io/badge/SwiftFormat-example)](https://example.com)

          Autocorrection explanation.

          </details>

        - <a id='included-rule'></a>(<a href='#included-rule'>link</a>) **Keep this summary.**

          <details>

          <!-- ai-skill-include: partial autocorrection -->

          [![SwiftFormat](https://img.shields.io/badge/SwiftFormat-example)](https://example.com)

          Full explanation of partial autocorrection.

          </details>

        ## Patterns

        - <a id='aliased-rule'></a><a id='old-rule'></a>(<a href='#aliased-rule'>link</a>) **One rule with two anchors.**

          <details>

          Alias explanation.

          </details>

        **[⬆ back to top](#table-of-contents)**

        ## Amendments

        Amendment text.
      MARKDOWN
    end

    around do |example|
      Dir.mktmpdir('swift-skill-spec') do |directory|
        @directory = directory
        FileUtils.mkdir_p(File.join(directory, 'src', 'assets', 'css'))
        File.write(File.join(directory, 'README.md'), readme)
        example.run
      end
    end

    subject(:site_content) do
      described_class.new(site_dir: File.join(@directory, 'src'),
        skill_dir: File.join(@directory, 'swift'), readme_path: File.join(@directory, 'README.md'))
    end

    def archive_entries
      stdout, stderr, status = Open3.capture3('unzip', '-Z1', site_content.skill_zip_path)
      expect(status.success?).to be(true), stderr
      stdout.lines.map(&:chomp).reject { |entry| entry.end_with?('/') }
    end

    it 'extracts all rule forms and treats alias anchors as a single rule' do
      expect(site_content.rule_contents.keys).to eq(%w[
        plain-rule brief-rule mixedCase-rule autocorrected-rule included-rule aliased-rule
      ])
      expect(site_content.rule_contents.fetch('brief-rule')).to eq("**A rule without details.**\n")
      expect(site_content.rule_contents.fetch('aliased-rule')).to eq(
        "**One rule with two anchors.**\n\nAlias explanation.\n")
    end

    it 'keeps rule details separate from neighboring rules, subsections, and navigation' do
      expect(site_content.rule_contents.fetch('plain-rule')).not_to include('A rule without details')
      expect(site_content.rule_contents.fetch('brief-rule')).not_to include('Functions')
      expect(site_content.rule_contents.fetch('included-rule')).not_to include('Patterns')
      expect(site_content.rule_contents.fetch('aliased-rule')).not_to include('Amendment', 'back to top')
    end

    it 'keeps the summary concise and selects rules independently of their bullet style' do
      content = site_content.skill_md_content
      expect(content).to include('[mixedCase-rule] A starred rule.', '[included-rule] Keep this summary.')
      expect(content).not_to include('autocorrected-rule', 'Autocorrection explanation', '#### Why?')
      expect(content).not_to include('Starred rule explanation', 'old-rule', '<a ')
      expect(content).to include('[plain-rule] Use clear names.')
    end

    it 'preserves full details while removing the containing list indentation and wrappers' do
      expect(site_content.rule_contents.fetch('plain-rule')).to eq(<<~MARKDOWN)
        **Use clear names.**

        #### Why?

        Preserve the explanation, [other rule](https://swift.airbnb.tech/#mixedCase-rule), and [section](https://swift.airbnb.tech/#naming).

        ```swift
        let value = "<tag> & {{ template }}"
        if value.isEmpty {
          print(value)
        }
        ```

        _Exception: Keep meaningful abbreviations._
      MARKDOWN
    end

    it 'removes shield badges while retaining other images, links, and rule explanations' do
      badge = '[![SwiftLint](https://img.shields.io/badge/SwiftLint-example.svg)](https://example.com/rule)'
      image = '[![Diagram](https://example.com/diagram.png)](https://example.com/diagram)'
      File.write(site_content.readme_path, readme.sub('Starred rule explanation.',
        "Starred rule explanation. #{badge}\n\n  #{image}\n\n  [Reference](https://example.com/reference)"))
      content = site_content.rule_contents.fetch('mixedCase-rule')
      expect(content).to include('Starred rule explanation.', image, '[Reference](https://example.com/reference)')
      expect(site_content.rule_contents.values.join).not_to include('img.shields.io')
    end

    it 'rejects duplicate rule IDs rather than silently overwriting their guidance' do
      File.write(site_content.readme_path, readme + "\n- <a id='plain-rule'></a> Duplicate.\n")
      expect { site_content.rule_contents }.to raise_error('Duplicate rule ID: plain-rule')
    end

    it 'writes the index with the full guide and page metadata' do
      site_content.write_index
      page = File.read(site_content.index_path)
      expect(page).to start_with("---\nlayout: default\n")
      expect(page).to include('title: Airbnb Swift Style Guide', 'Goal text.', '<details>')
      expect(page).to include('Autocorrection explanation')
      expect(page).not_to include('Amendment text.')
    end

    it 'writes the raw skill with Jekyll metadata separate from skill frontmatter' do
      site_content.write_skill_md_raw
      page = File.read(site_content.ai_skill_raw_path)
      expect(page).to eq("---\nlayout: raw\npermalink: /SKILL.md\n---\n" + site_content.skill_md_content)
    end

    it 'writes a highlighted preview linking all summary IDs to rule pages' do
      site_content.write_skill_md
      page = File.read(site_content.ai_skill_page_path)
      expect(page).to include('Download: [skills/swift.zip](/skills/swift.zip)', 'class="language-markdown highlighter-rouge"')
      expect(page).not_to include('Raw `SKILL.md` can be downloaded')
      expect(page).not_to include('Select a rule ID below to read its full guidance.')
      %w[plain-rule brief-rule mixedCase-rule included-rule aliased-rule].each do |id|
        expect(page).to include(%(<a href="/skill/#{id}">#{id}</a>))
      end
      expect(page).not_to include('href="/skill/autocorrected-rule"')
      expect(page).not_to match(/\]\(rules\//)
    end

    it 'leaves bracketed text that is not a rule ID unlinked' do
      File.write(site_content.readme_path, readme.sub('**Use clear names.**', '**Use [placeholder] for a value.**'))
      site_content.write_skill_md
      page = File.read(site_content.ai_skill_page_path)
      expect(page).to include('[placeholder]')
      expect(page).not_to include('href="/skill/placeholder"')
    end

    it 'escapes HTML in the Markdown preview without evaluating Liquid examples' do
      File.write(site_content.readme_path, readme.sub('**Use clear names.**', '**Use `<tag> & {{ template }}`.**'))
      site_content.write_skill_md
      page = File.read(site_content.ai_skill_page_path)
      expect(page).to include('&lt;tag&gt; &amp; {{ template }}')
      expect(page).not_to include('<tag>')
      expect(page).to include('{% raw %}', '{% endraw %}')
    end

    it 'packages only SKILL.md and one full file per rule, excluding unrelated files' do
      FileUtils.mkdir_p(site_content.skill_dir)
      File.write(File.join(site_content.skill_dir, 'notes.txt'), 'Unrelated file that should not be packaged.')
      site_content.write_skill_bundle
      expected_files = ['swift/SKILL.md'] + site_content.rule_contents.keys.map { |id| "swift/rules/#{id}.md" }
      expect(archive_entries).to match_array(expected_files)

      extracted = File.join(@directory, 'extracted')
      _, stderr, status = Open3.capture3('unzip', '-q', site_content.skill_zip_path, '-d', extracted)
      expect(status.success?).to be(true), stderr
      main = File.read(File.join(extracted, 'swift/SKILL.md'))
      expect(main).to eq(site_content.skill_md_content)
      expect(main).not_to include('layout: raw', 'permalink:')
      site_content.rule_contents.each do |id, content|
        path = "swift/rules/#{id}.md"
        actual = File.read(File.join(extracted, path))
        expect(actual).to eq(File.read(File.join(@directory, path)))
        expect(actual).to eq("# #{id}\n\n#{content}")
      end
      main.scan(/^\[([^\]]+)\]/).flatten.each do |id|
        expect(File).to exist(File.join(extracted, 'swift', 'rules', "#{id}.md"))
      end
    end

    it 'writes one detail page per canonical ID with metadata, navigation, and full guidance' do
      site_content.write_skill_rule_pages
      files = Dir.glob(File.join(site_content.skill_pages_dir, '*.md'))
      expect(files.map { |file| File.basename(file, '.md') }).to match_array(site_content.rule_contents.keys)
      site_content.rule_contents.each do |id, content|
        page = File.read(File.join(site_content.skill_pages_dir, "#{id}.md"))
        metadata = YAML.safe_load(page.split('---', 3)[1])
        expect(metadata).to include('layout' => 'default', 'permalink' => "/skill/#{id}")
        expect(metadata.fetch('title')).to include(id)
        expect(metadata.fetch('description')).to include(id)
        expect(page).to include('[← Swift AI Skill](/skill)', "# #{id}\n", content)
      end
    end

    it 'removes stale rule files, pages, and ZIP entries after a rule is deleted' do
      site_content.write_skill_bundle
      site_content.write_skill_rule_pages
      File.write(site_content.readme_path, readme.split('## Patterns').first)
      site_content.write_skill_bundle
      site_content.write_skill_rule_pages
      expect(File).not_to exist(File.join(site_content.skill_dir, 'rules/aliased-rule.md'))
      expect(File).not_to exist(File.join(site_content.skill_pages_dir, 'aliased-rule.md'))
      expect(archive_entries).not_to include('swift/rules/aliased-rule.md')
      expect(File.read(File.join(site_content.skill_dir, 'SKILL.md'))).not_to include('aliased-rule')
    end

    it 'reports archive creation failures' do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).with('zip', '-q', '-r', site_content.skill_zip_path,
        'swift/SKILL.md', 'swift/rules', chdir: @directory).and_return(['', 'zip error', status])
      expect { site_content.write_skill_bundle }.to raise_error("zip failed:\nzip error")
    end

    it 'writes syntax highlighting CSS' do
      site_content.generate_syntax_css
      expect(File.read(site_content.syntax_css_path)).to include('.highlight', 'color:')
    end

    it 'reports syntax highlighting failures' do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).with('bundle', 'exec', 'rougify', 'style', 'github.light')
        .and_return(['', 'rougify error', status])
      expect { site_content.generate_syntax_css }.to raise_error("rougify failed:\nrougify error")
    end
  end

  describe 'rendered Jekyll site' do
    before(:context) do
      @directory = Dir.mktmpdir('swift-site-spec')
      source = File.join(@directory, 'src')
      FileUtils.mkdir_p(File.join(source, 'assets/css'))
      %w[_config.yml _includes _layouts plugin.md].each do |path|
        FileUtils.cp_r(File.join(__dir__, 'src', path), source)
      end
      FileUtils.cp(File.join(__dir__, 'src/assets/css/style.css'), File.join(source, 'assets/css/style.css'))
      @generator = SiteContent.new(site_dir: source, skill_dir: File.join(@directory, 'swift'))
      @generator.write_index
      @generator.write_skill_md
      @generator.write_skill_md_raw
      @generator.write_skill_bundle
      @generator.write_skill_rule_pages
      @generator.generate_syntax_css
      @destination = File.join(@directory, 'built')
      config = Jekyll.configuration('source' => source, 'destination' => @destination, 'quiet' => true)
      Jekyll::Site.new(config).process
    end

    after(:context) do
      FileUtils.rm_rf(@directory) if @directory
    end

    def rendered_page(path)
      File.read(File.join(@destination, "#{path}.html"))
    end

    it 'publishes the full style guide, package plugin, and syntax CSS' do
      expect(rendered_page('index')).to include('Airbnb Swift Style Guide', '<details>')
      expect(rendered_page('plugin')).to include('<h1 id="airbnb-swift-package-plugin">Airbnb Swift Package Plugin</h1>')
      expect(File.read(File.join(@destination, 'assets/css/syntax.css'))).to include('.highlight')
    end

    it 'publishes a downloadable ZIP unchanged by Jekyll' do
      expect(rendered_page('skill')).to include('href="/skills/swift.zip"')
      expect(File.binread(File.join(@destination, 'skills/swift.zip'))).to eq(File.binread(@generator.skill_zip_path))
      expect(File).not_to exist(File.join(@destination, 'swift.zip'))
    end

    it 'renders the Markdown preview faithfully with live links for every summary ID' do
      page = rendered_page('skill')
      expect(page).to include('<h1 id="airbnb-swift-ai-skill">Airbnb Swift AI Skill</h1>')
      preview = page[/<pre class="highlight skill-preview"><code>(.*?)<\/code><\/pre>/m, 1]
      expect(CGI.unescapeHTML(preview.gsub(/<[^>]*>/, ''))).to eq(@generator.skill_md_content)
      ids = @generator.skill_md_content.scan(/^\[([^\]]+)\]/).flatten
      expect(page.scan(%r{<a href="/skill/([^"]+)">}).flatten).to match_array(ids)
      ids.each do |id|
        expect(File).to exist(File.join(@destination, 'skill', "#{id}.html"))
      end
    end

    it 'publishes full rule pages, including the Swift Testing example' do
      @generator.rule_contents.each_key do |id|
        expect(rendered_page("skill/#{id}")).to include("<h1 id=\"#{id.downcase}\">#{id}</h1>")
      end
      page = rendered_page('skill/swift-testing-test-case-names')
      expect(page).to include('Raw identifiers with spaces are easier to read', 'href="/skill"')
      expect(page).to include('SE-0451')
      expect(CGI.unescapeHTML(page.gsub(/<[^>]*>/, ''))).to include('warp drive enables FTL travel')
      expect(page).not_to include('{% raw %}', 'ai-skill-include')
    end

    it 'keeps the raw SKILL.md endpoint compatible' do
      expect(File.read(File.join(@destination, 'SKILL.md'))).to eq(@generator.skill_md_content)
    end

    it 'highlights the AI Skill navigation on summary and rule pages only' do
      %w[skill skill/swift-testing-test-case-names].each do |path|
        expect(rendered_page(path)).to include('href="/skill" class="nav-link active"')
      end
      %w[index plugin].each do |path|
        expect(rendered_page(path)).not_to include('href="/skill" class="nav-link active"')
      end
    end
  end
end
