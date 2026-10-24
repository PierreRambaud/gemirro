# frozen_string_literal: true

require 'spec_helper'
require 'gemirro/utils'

# Utils tests
module Gemirro
  describe Utils do
    describe '.safe_homepage' do
      it 'keeps http and https URLs' do
        expect(Utils.safe_homepage('http://example.com')).to eq('http://example.com/')
        expect(Utils.safe_homepage('https://example.com/foo?a=1')).to eq('https://example.com/foo?a=1')
        expect(Utils.safe_homepage('HTTPS://Example.com/x')).to eq('https://example.com/x')
      end

      it 'rejects missing or empty values' do
        expect(Utils.safe_homepage(nil)).to be_nil
        expect(Utils.safe_homepage('')).to be_nil
        expect(Utils.safe_homepage("  \n")).to be_nil
      end

      [
        'javascript:alert(1)',
        'JavaScript:alert(1)',
        ' javascript:alert(1)',
        "java\tscript:alert(1)",
        "java\nscript:alert(1)",
        "\u0000javascript:alert(1)",
        'data:text/html,<script>alert(1)</script>',
        'vbscript:msgbox(1)',
        'file:///etc/passwd',
        'javascript%3Aalert(1)',
        '//evil.example.com',
        '/relative/path',
        'https://'
      ].each do |value|
        it "rejects #{value.inspect}" do
          expect(Utils.safe_homepage(value)).to be_nil
        end
      end
    end
  end
end
