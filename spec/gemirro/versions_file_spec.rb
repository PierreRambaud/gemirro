require 'spec_helper'
require 'zlib'
require 'gemirro/versions_file'

# VersionsFile tests
module Gemirro
  describe 'VersionsFile' do
    include FakeFS::SpecHelpers

    it 'should load versions file' do
      spec = %(created_at: 2025-01-01T00:00:00Z\n---\ngemirro 0.0.1.alpha1,0.0.1,0.0.2.alpha2,0.0.2 checksum)

      result = VersionsFile.new(spec)
      expect(result).to be_a(VersionsFile)

      expect(result.versions_string).to eq(%(created_at: 2025-01-01T00:00:00Z\n---\ngemirro 0.0.1.alpha1,0.0.1,0.0.2.alpha2,0.0.2 checksum))

      expect(result.versions_hash).to eq(
        'gemirro' => [
          ['gemirro', ::Gem::Version.new('0.0.1.alpha1'), 'ruby'],
          ['gemirro', ::Gem::Version.new('0.0.1'), 'ruby'],
          ['gemirro', ::Gem::Version.new('0.0.2.alpha2'), 'ruby'],
          ['gemirro', ::Gem::Version.new('0.0.2'), 'ruby']
        ]
      )
    end
  end
end
