# Link Checker API

**⚠️ This service is in Alpha ⚠️**

A web service that takes an input of URIs. It performs a number of checks on
them to determine whether these are things that should be linked to.

## Nomenclature

- **Link**: The consideration of a URI and all resulting redirects
  that may occur from it.
- **Check**: The process of taking a URI and checking it as a Link
  for any problems that may affecting linking to it within content.
- **Batch**: The functionality to check multiple URIs in a grouping

## Technical documentation

This is a Ruby on Rails application that acts as web service for performing
links. Communication to and from this service is done through a RESTful JSON
API. The majority of link checking is done through a background worker than
uses Sidekiq. There is a webhook functionality for applications to receive
notifications when link checking is complete.

### Dependencies

- [PostgreSQL](https://www.postgresql.org/) - provides a database
- [redis](https://redis.io) - provides queue storage for Sidekiq jobs

### Running the application

Start the web app with:

`./startup.sh`

Application will be available on port 3208 - http://localhost:3208 or if you
are using the development VM http://link-checker-api.dev.gov.uk

Start the sidekiq worker with:

`bundle exec sidekiq -C config/sidekiq.yml`

### Running the test suite

`bundle exec rspec`

### Example API output

```
$ curl -s http://link-checker-api.dev.gov.uk/check\?uri\=https%3A%2F%2Fwww.gov.uk%2F\&synchronous\=true | jq
{
  "uri": "https://www.gov.uk/",
  "status": "ok",
  "checked": "2017-04-12T18:47:16Z",
  "errors": {},
  "warnings": {}
}
```

## Licence

[MIT License](LICENSE)
