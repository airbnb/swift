# frozen_string_literal: true

require_relative 'site_content'
require 'tmpdir'
require 'cgi'
require 'jekyll'

RSpec.describe SiteContent do
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
