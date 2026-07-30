# frozen_string_literal: true

require "test_helper"
require "yaml"
require "the_local/provider_check"

module Cs133
  class TheLocalTest < Minitest::Test
    THE_LOCAL_DIR = File.expand_path("../../the_local", __dir__)
    AGENTS_DIR = File.join(THE_LOCAL_DIR, "agents")

    def test_every_local_carries_the_scope_the_manifest_declares
      declared = YAML.safe_load_file(File.join(THE_LOCAL_DIR, "interface.yml"))["scope"]

      assert(local_scopes.all? { |scope| scope == declared })
    end

    def local_scopes
      Dir.glob(File.join(AGENTS_DIR, "*.md")).map do |file|
        YAML.safe_load(File.read(file)[/\A---\n.*?\n---\n/m])["scope"]
      end
    end

    def test_the_locals_satisfy_the_provider_contract
      assert_empty TheLocal::ProviderCheck.new(File.expand_path("../..", __dir__)).problems
    end

    def test_reference_documents_every_canonical_section
      headings = ["### Interface", "### Recipe", "### Install", "### Conventions"]

      assert(headings.all? { |heading| Cs133::Reference.content.include?(heading) })
    end

    def test_reference_holds_no_unresolved_placeholder
      refute_includes Cs133::Reference.content, "TODO:"
    end
  end
end
