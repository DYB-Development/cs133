# frozen_string_literal: true

require "test_helper"
require "yaml"

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

    def test_info_local_embeds_the_current_reference
      assert_includes File.read(File.join(AGENTS_DIR, "cs133-info.md")), Cs133::Reference.content
    end

    def test_install_local_embeds_the_current_reference
      assert_includes File.read(File.join(AGENTS_DIR, "cs133-install.md")), Cs133::Reference.content
    end

    def test_develop_local_embeds_the_current_reference
      assert_includes File.read(File.join(AGENTS_DIR, "cs133-develop.md")), Cs133::Reference.content
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
