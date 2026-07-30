# frozen_string_literal: true

require "test_helper"

module Cs133
  class TheLocalTest < Minitest::Test
    AGENTS_DIR = File.expand_path("../../the_local/agents", __dir__)

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
