# Suspicious domains

Link Checker API has a table of 'suspicious domains'. It is a small table, not a comprehensive list of every suspicious domain on the internet.

Any link that links to a domain in that table is considered dangerous (a link with a state of 'danger': a state [introduced in March 2025](https://github.com/alphagov/link-checker-api/pull/969) that is currently only set by this one scenario).

It is up to downstream applications to decide what to do with dangerous links. In Whitehall, for example, dangerous links are [automatically removed from editions, which are then automatically republished](https://github.com/alphagov/whitehall/pull/10081). The 'suspicious domain' model was introduced as a way to reasonably reliably and quickly purge Whitehall of all links to dangerous domains (Whitehall re-checks all of its links on [roughly a weekly basis](https://github.com/alphagov/whitehall/pull/10077), so most dangerous links would be removed within a week of creating a new 'suspicious domain').

As an aside, care must therefore be taken when adding a domain to the table. One can therefore imagine the mess that could be caused by, say, accidentally adding `gov.uk` to the list of suspicious domains!

## Adding a suspicious domain

Domains are added to the table by running this in a Rails console:

```ruby
SuspiciousDomain.create(domain: "malicious.example.com")
```

There is some validation to ensure that each domain is unique and that there are no additional parts to the domain (such as protocol, or path).
