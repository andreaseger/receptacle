# --------------------------------------------------------------------------------------------------------------------
# Has any changes happened inside the actual library code?
# --------------------------------------------------------------------------------------------------------------------
has_app_changes = !git.modified_files.grep(/lib/).empty?
has_test_changes = !git.modified_files.grep(/test/).empty?
is_version_bump = git.modified_files.sort == ["CHANGELOG.md", "lib/danger/version.rb"].sort

if has_app_changes && !has_test_changes && !is_version_bump
  warn("Tests were not updated. That's OK if you're refactoring existing code.", sticky: false)
end

changelog.have_you_updated_changelog?

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "WIP"

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

commit_lint.check warn: :all

# Coverage
simplecov.report('coverage/coverage.json')

# rubocop
rubocop.lint
