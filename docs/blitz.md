# End of blitz summary - April 2017

This project was created during the 2 week GOV.UK blitz of April 2017, this
document serves as a round up of what we consider the next steps of this
project could be and areas we feel could be improved.

## Contents

- [Define a "good enough" format for errors or warnings](#define-a-good-enough-format-for-errors-or-warnings)
- [A more modular approach to defining the link checking](#a-more-modular-approach-to-defining-the-link-checking)
- [Do we have too many warnings? Or not enough?](#do-we-have-too-many-warnings-or-not-enough)
- [Decide what to do with HEAD/GET requests](#decide-what-to-do-with-headget-requests)
- [Further URI checks](#further-uri-checks)
- [Checks based on history of a link](#checks-based-on-history-of-a-link)
- [Authentication with GDS SSO](#authentication-with-gds-sso)
- [Client side-integration](#client-side-integration)
- [A Rails pattern to simplify controllers](#a-rails-pattern-to-simplify-controllers)
- [Whitehall monthly link check / polling implementation](#whitehall-monthly-link-check--polling-implementation)
- [Local links manager warnings](#local-links-manager-warnings)

## Define a "good enough" format for errors or warnings

Throughout the blitz we adopted different formats for reporting issues back to
users.

It started with:

`"problem_code": "Human readable message"`

Then we realised in the case of redirects you could have the same warning
multiple times so it evolved to:

`"problem_code": ["Human readable message", "another human readable message potentially"]`

After this we experimented with implementations and learnt that our messages
were quite long to display in full and that there was a need to have a short
human readable message to summarise them. So the message increased in
complexity to:

```
"problem_code": {
  "short_description": "Short message",
  "long_description": ["Human readable message", "another human readable message potentially"]`
}
```

We then wanted to simplify this and felt that we could use the `problem_code`
attribute as the short description so we settled on this:

`"Short message": ["Human readable message", "another human readable message potentially"]`

This does the job but doesn't really sit right with us, it feels a bit too
opaque for the purpose of the various strings and the array of messages can
produce confusing results when messages are repeated.

Finally the actual content of the message has been a challenge, luckily we had
Ben who did research and helped define the technical level of the users of the
messages. Although we have still ended up a little stuck where we
have lots of problematic scenarios to explain but we are writing to
an audience technical level that may not care about the differentiations.

### How we could improve this

Considering that this service produces messages that should be output directly
to end users we need to identify something that is good enough for that purpose,
but not too tied into a particular applications implementation. It feels
reasonable that a short form of an error is included, but we should also see if
we can find a way to avoid an array of messages - as these can be confusing
repeated.

A rough suggestion on how we could format them is as follows:

```
[{
  "code": "problem_code",
  "title": "Short message",
  "details": "Human readable message that can cover multiple warnings"
}]
```

Other options could be to include a technical message and a non-technical
message so the application implementing it chooses what to display depending
on their audience. There could even be a `"suggested_fix"` field and the need
for the `"code"` attribute is still debatable.

We're also wondering whether rather than storing full messages we'd be more
efficient to store the `problem_code` and the parameters used to generate the
message.

**A solution to this was found during the firebreak in July 2017.**

## A more modular approach to defining the link checking

The approach we have taken to defining the checks on the links have quite a lot
of responsibilities and are coupled with the content of the warnings/errors.

If we are to aim to make the checks more extensible we should consider
refactoring how the checks work so that individual checks can be more self
contained and isolated.

## Do we have too many warnings? Or not enough?

We have a concept of warnings which is used to indicate problems we've found
with links that might (or even probably) mean the link shouldn't be linked to
but depending on the context might still want to/have to - eg a link that is
slow, or a valid reason to link to "mature" content.

These warnings are somewhat problematic as if a user wants to proceed with the
link they are just noise. Life is significantly simpler when links are binary:
good or broken.

It would be good to determine do we generate too many of these, or we might
possibly find some of the things we identify as broken are actually warnings.

## Decide what to do with HEAD/GET requests

We encountered a problem late in the blitz process that a number of the links
we were testing were not correctly following the HTTP protocol and were
responding with 404 for HEAD requests and 200 to GET requests - these all seem
to originate from Microsoft IIS/8.5 but we didn't know if it was the framework
or implementation that was the problem.

This has the unfortunate consequence that to reliably test we have to perform
GET requests. For the most part this is fine except in the instances where
links could be to large files (such as pdf documents or applications) and we may
inadvertently be flagging these as slow or as timeouts.

We should have a good think about this issue and weigh up the pros and cons and
how we should proceed. Could be that we perform a HEAD then a GET even if 404,
or find a way to do a GET without getting content, or just dealing with the
content of a GET.

## Further URI checks

There are various other checks that could be performed on URIs. Here's a list
of some of the ones identified:

- Check for UTF-8 Characters - where a IRI is linked to without encoding
- Check for existence of a fragment on text/html page
- Check page content against spam database / more simplistic word list
- Support mailto scheme and the appropriate email validation
- Support tel scheme
- Popular app store schemes

## Checks based on history of a link

A number of the originally suggested ideas involved the history of a link to
alleviate the risks of squatting on pages that were linked to from government
websites.

We considered this work to be outside of the scope of the blitz but did
consider this check:

- Storing the time a DNS record was changed and alerting if it has changed in
last 2 weeks

After more thought though it is probably best to only consider doing historical
checks based on our own storage to avoid the false positives of anything newly
created.

The somewhat challenging aspect of this is that for this to be helpful you'd
want it to be proactively checking documents from the past. As for the most
part, if you are authoring new content you've probably found the links, and if
you are editing old content it could be very difficult to determine what a
recent change is.

### Some ideas on what we could implement

We could store, in separate tables to the link checking, some historical
information about hosts and normalised URIs. This could allow us to build up
simple databases to know when a redirect destination changes, domain
ownership, or some rudimentary word analysis.

We could then use the length of time we have known about the page to judge
when it is of concern.

There is possibility that when creating batches we get sent some sort of
document identifier so we can use that for some context, eg whether things have
changed since last check. This adds complexity though and will reduce
consistency of link checking results.

### Related ideas

We could allow additional API methods to blacklist hosts if for some reason
they are now no longer safe to be linked to.

We could develop a system that performs regular checks to detect dubious
changes and develop a way for humans to confirm if they are problematic.

## Authentication with GDS SSO

We spent most of the blitz with GDS SSO integrated and decided to pull it at
the end as we would have to set up a bunch of tokens for usage and weren't
using the authentication.

If this is ever publicly accessible then we should definitely have
authentication.

While this application is only internally accessible we're not sure if
authentication adds anything, though if we were to add it it would probably be
just for the batch endpoint and restrict users to just viewing batches they
have created.

This also ties into client-side integration.

## Client side-integration

Usage of this API involves setting up a methods that call this API, an endpoint
for the webhook and a means to report that back to the user. This feels like
quite a lot of lifting particularly for some of the more lo-fi publishing
applications.

What we felt would be nice is if we were able to embed this into an application
via JavaScript which could extract links from a block of text call the API
and return the details. This would be a far simpler integration but lack
the ability to store problems between requests. An anticipated problem is
authentication.

## A Rails pattern to simplify controllers

As ever we've got caught in the Rails trap of controllers being a bit too
complicated and having not identified a nice pattern to simplify them.

There is the option of the [Command][pub-api-command] pattern used in
publishing API, although this has the disadvantage that in conflicts with the
[Command](https://en.wikipedia.org/wiki/Command_pattern) design pattern. A
better option might be to define these as services.

## Whitehall monthly link check / polling implementation

The Whitehall monthly link checker is an interesting implementation to complete.
As it runs as an isolated rake task it doesn't make sense to utilise the
webhook - thus the approach used is to poll for complete batches.

The challenge here is to find a simple way for it to not slip into the
following scenarios:

- Failing on a single HTTP problem, eg a single timeout
- Getting stuck in an eternal loop
- Crash the Link Checker API
- Fire lots of unnecessary requests

It's probably worth working out if this can be done with a relatively simple
implementation that can be copied or if it needs something more complex that
should be moved somewhere that can be shared.

## Local links manager warnings

Local links manager implementation is very close to being complete, the
remaining aspect is to assess the warnings that have been flagged against links
and check that they seem helpful.

Problems we currently have are:

- confusing duplicate messages, where different points of a redirect have the
  same issue;
- for links with multiple warnings we show the title of just the first one.

[pub-api-command]: https://github.com/alphagov/publishing-api/blob/master/app/commands/v2/put_content.rb
