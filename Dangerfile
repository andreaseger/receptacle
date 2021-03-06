# frozen_string_literal: true

# -------------------------------------------------------------------------
# Has any changes happened inside the actual library code?
# -------------------------------------------------------------------------
has_app_changes = !git.modified_files.grep(/lib/).empty?
has_test_changes = !git.modified_files.grep(/test/).empty?
is_version_bump = git.modified_files.sort == ["CHANGELOG.md", "lib/receptacle/version.rb"].sort

if has_app_changes && !has_test_changes && !is_version_bump
  warn("Tests were not updated. That's OK if you're refactoring existing code.", sticky: false)
end

if !git.modified_files.include?("CHANGELOG.md") && has_app_changes
  fail(<<~MSG)
    Please include a CHANGELOG entry.
    You can find it at [CHANGELOG.md](https://github.com/andreaseger/receptacle/blob/master/CHANGELOG.md).
  MSG
  message "Note, we hard-wrap at 80 chars and use 2 spaces after the last line."
end

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "WIP"

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

commit_lint.check warn: :all, disable: [:subject_cap]

# rubocop
rubocop.lint force_exclusion: true
