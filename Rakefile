require 'json'
require 'net/http'
require 'json'
require 'tempfile'

namespace :lint do
  desc 'Lints swift files'
  task :swift do
    sh 'swift package --allow-writing-to-package-directory format --lint'
  end
end

namespace :format do
  desc 'Formats swift files'
  task :swift do
    sh 'swift package --allow-writing-to-package-directory format'
  end
end

namespace :update do
  desc 'Updates SwiftFormat to the latest version'
  task :swiftformat do
    # Find the most recent nightly release of SwiftFormat in the https://github.com/calda/SwiftFormat-nightly repo.
    response = Net::HTTP.get(URI('https://api.github.com/repos/calda/SwiftFormat-nightly/releases/latest'))
    latest_release_info = JSON.parse(response)

    latest_version_number = latest_release_info['tag_name']

    # Download the artifact bundle for the latest release and compute its checksum.
    temp_dir = Dir.mktmpdir
    artifact_bundle_url = "https://github.com/calda/SwiftFormat-nightly/releases/download/#{latest_version_number}/swiftformat.artifactbundle.zip"
    artifact_bundle_zip_path = "#{temp_dir}/swiftformat.artifactbundle.zip"

    sh "curl #{artifact_bundle_url} -L --output #{artifact_bundle_zip_path}"
    checksum = `swift package compute-checksum #{artifact_bundle_zip_path}`

    # Update the Package.swift file to reference this version
    package_manifest_path = 'Package.swift'
    package_manifest_content = File.read(package_manifest_path)

    updated_swift_format_reference = <<-EOS
    .binaryTarget(
      name: "swiftformat",
      url: "https://github.com/calda/SwiftFormat-nightly/releases/download/#{latest_version_number}/SwiftFormat.artifactbundle.zip",
      checksum: "#{checksum.strip}"
    ),
    EOS

    regex = /[ ]*.binaryTarget\([\S\s]*name: "swiftformat"[\S\s]*?\),\s/
    updated_package_manifest = package_manifest_content.gsub(regex, updated_swift_format_reference)
    File.open(package_manifest_path, "w") { |file| file.puts updated_package_manifest }

    puts "Updated Package.swift to reference SwiftFormat #{latest_version_number}"
  end
end

namespace :site do
  desc 'Prepares index.md and syntax highlighting assets'
  task :prepare do
    require_relative 'site/site_content'
    puts '📋 Generating index.md from README.md with frontmatter...'
    SiteContent.new.write_index
    puts '🎨 Generating syntax highlighting CSS...'
    SiteContent.new.generate_syntax_css
  end

  desc 'Builds the static site into _site/'
  task build: :prepare do
    env = { 'JEKYLL_ENV' => ENV.fetch('JEKYLL_ENV', 'production') }
    sh env, 'bundle exec jekyll build --source site/src'
  end

  desc 'Serves the site to support previewing its content during development'
  task serve: :prepare do
    env = { 'JEKYLL_ENV' => 'development' }
    sh env, 'bundle exec jekyll serve --source site/src'
  end

  desc 'Enables validating the README content used to build the site in local developement'
  task :filter_readme do
    require_relative 'site/site_content'
    puts SiteContent.new.filter_readme
  end
end
