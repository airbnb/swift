# frozen_string_literal: true

require_relative 'site_content'

# Basic integration tests for `site_content.rb`,
# validating the high level structure of the content.
RSpec.describe SiteContent do
  subject(:site_content) { described_class.new }

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
  end

  describe 'SKILL.md' do
    let(:skill_content) { site_content.skill_md_content }
    let(:readme_content) { File.read(site_content.readme_path) }

    it 'includes frontmatter with description' do
      expect(skill_content).to include('description: Always use when creating and editing Swift files')
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

    it 'does not include markdown links' do
      expect(skill_content).not_to match(/\[.*\]\(.*\)/)
      expect(readme_content).to match(/\[.*\]\(.*\)/)
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

  end
end
