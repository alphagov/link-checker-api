# Link Checker API

A web service that takes an input of URIs. It performs a number of checks on them to determine whether these are things that should be linked to.

## Nomenclature

- **Link**: The consideration of a URI and all resulting redirects that may occur from it.
- **Check**: The process of taking a URI and checking it as a Link for any problems that may affecting linking to it within content.
- **Batch**: The functionality to check multiple URIs in a grouping.

## Technical documentation

This is a Ruby on Rails app, and should follow [our Rails app conventions](https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html).

You can use the [GOV.UK Docker environment](https://github.com/alphagov/govuk-docker) to run the application and its tests with all the necessary dependencies. Follow [the usage instructions](https://github.com/alphagov/govuk-docker#usage) to get started.

**Use GOV.UK Docker to run any commands that follow.**

### Running the test suite

```
bundle exec rake
```

### Further documentation

Check the [docs](docs) directory.

## Licence

[MIT License](LICENSE)
