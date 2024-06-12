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
    # Find the most recent release of SwiftFormat in the https://github.com/calda/SwiftFormat repo.
    response = Net::HTTP.get(URI('https://api.github.com/repos/calda/SwiftFormat/releases/latest'))
    latest_release_info = JSON.parse(response)

    latest_version_number = latest_release_info['tag_name']

    # Download the artifact bundle for the latest release and compute its checksum.
    temp_dir = Dir.mktmpdir
    artifact_bundle_url = "https://github.com/calda/SwiftFormat/releases/download/#{latest_version_number}/swiftformat.artifactbundle.zip"
    artifact_bundle_zip_path = "#{temp_dir}/swiftformat.artifactbundle.zip"
    
    sh "curl #{artifact_bundle_url} -L --output #{artifact_bundle_zip_path}"
    checksum = `swift package compute-checksum #{artifact_bundle_zip_path}`

    # Update the Package.swift file to reference this version
    package_manifest_path = 'Package.swift'
    package_manifest_content = File.read(package_manifest_path)
    
    updated_swift_format_reference = <<-EOS
    .binaryTarget(
      name: "swiftformat",
      url: "https://github.com/calda/SwiftFormat/releases/download/#{latest_version_number}/SwiftFormat.artifactbundle.zip",
      checksum: "#{checksum.strip}"),
    EOS
    
    regex = /[ ]*.binaryTarget\([\S\s]*name: "swiftformat"[\S\s]*?\),\s/
    updated_package_manifest = package_manifest_content.gsub(regex, updated_swift_format_reference)
    File.open(package_manifest_path, "w") { |file| file.puts updated_package_manifest }
    
    puts "Updated Package.swift to reference SwiftFormat #{latest_version_number}"
  end
end
