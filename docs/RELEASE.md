# Release Process Checklist

1. Update `active_record_doctor.gemspec` with new information and dependencies.
2. Ensure `README.md` and `CHANGELOG.md` are up to date; give credit where it's due.
3. Create a commit that bumps the version number and sets the appropriate header
   in `CHANGELOG.md`.
4. Ensure the build is green.
5. Release a new version of the gem via `bundle exec rake "release[origin]"`.
6. Announce the new release!
