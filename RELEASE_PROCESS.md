# Release Process Checklist

## Working on a new release

* [ ] Update `active_record_doctor.gemspec` with new information and
  dependencies
* [ ] Update `README.md` with new features, examples and use cases.
* [ ] Add an entry to `CHANGELOG.md`. Give credit where it's due.

## Releasing a new version

* [ ] Create a commit that bumps the version number and sets the appropriate
  header in `CHANGELOG.md`.
* [ ] Review `README.md` to ensure it documents the tool appropriately.
* [ ] Ensure the build is green.
* [ ] Create a tag with the right version number. Push the tag to GitHub.
* [ ] Build the gem with `gem build active_record_doctor.gemspec`.
* [ ] Ensure the generated gem can be installed properly in a new project.
* [ ] Publish to RubyGems.org with `gem push <GEM NAME>`.
* [ ] Ensure the gem can be installed properly using RubyGems.org.
* [ ] Make an announcement to `ruby-talk`, `rubyonrails-talk` Google Groups.
* [ ] Make an announcement to Bootstrapped, #smallbiz, Ruby developer, Ruby on
  Rails link, slashrocket, and Launch Slack communities.
