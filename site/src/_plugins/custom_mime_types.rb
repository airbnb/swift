# frozen_string_literal: true

require 'webrick'

module WEBrick
  module HTTPUtils
    class << self
      alias_method :original_mime_type, :mime_type

      def mime_type(filename, mime_tab)
        # Only serve /CLAUDE.md as HTML, keep /raw/CLAUDE.md as markdown
        if filename.end_with?('/CLAUDE.md') && !filename.include?('/raw/')
          return 'text/html'
        end
        original_mime_type(filename, mime_tab)
      end
    end
  end
end
