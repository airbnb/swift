# frozen_string_literal: true

require_relative 'site_content'
require 'tmpdir'

RSpec.describe SiteContent do
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

        ### Closures

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
      expect(content).to include('### Functions', '### Closures')
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
end
