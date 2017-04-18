# Link Checker API's API

## Endpoints

- [`GET /check`](#get-check)
- [`POST /batch`](#post-batch)
- [`GET /batch/:id`](#get-batchid)

## Webhook

- [Batch complete webhook](#batch-complete-webhook)

## Entities

- [`LinkReport`](#linkreport-entity)
- [`BatchReport`](#batchreport-entity)

## `GET /check`

<details>
  <summary>Example usage</summary>

```
$ curl -s http://link-checker-api.dev.gov.uk/check\?uri\=https%3A%2F%2Fwww.gov.uk%2F | jq
{
  "uri": "https://www.gov.uk/",
  "status": "pending",
  "checked": null,
  "errors": {},
  "warnings": {}
}
```

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

</details>

This endpoint is used to check a single link. If the link has been checked
within a time specified (default 24 hours) it will return the results from
that check, otherwise it will queue a check and return a pending report. You
can force it to return a completed check with the `synchronous` parameter.

### Query string attributes

- `uri` *(required)*
  - The URI to the link to be checked
- `checked_within` *(optional, defaults to 86400)*
  - An integer value of the number of seconds in the past that checks for this
    link are valid.
  - Use 0 to ensure the link is checked again
- `synchronous` *(optional, defaults to false)*
  - A boolean value to specify to check the URI during this request, this may
    cause a slow/timeout response, use with caution.

### Returns

A [`LinkReport`](#linkreport-entity)

## `POST /batch`

<details>
  <summary>Example usage</summary>

```
$ curl -s -H "Content-Type: application/json" -X POST -d '{"uris": ["https://www.gov.uk/", "https://www.gov.uk/search", "https://www.gov.uk/404"], "webhook_uri": "http://my-awesome-micro.service/link-checker-callback", "webhook_secret_token": "AzfenrtbCBMqqta1WEh3BQgViXZQtEdXCxBQ1P9VKN4="}' http://link-checker-api.dev.gov.uk/batch | jq
{
  "id": 137125,
  "status": "in_progress",
  "links": [
    {
      "uri": "https://www.gov.uk/",
      "status": "ok",
      "checked": "2017-04-12T18:47:16Z",
      "errors": {},
      "warnings": {}
    },
    {
      "uri": "https://www.gov.uk/404",
      "status": "broken",
      "checked": "2017-04-12T16:30:39Z",
      "errors": {
        "404 error (page not found)": [
          "Received 404 response from the server."
        ]
      },
      "warnings": {}
    },
    {
      "uri": "https://www.gov.uk/search",
      "status": "pending",
      "checked": null,
      "errors": {},
      "warnings": {}
    }
  ],
  "totals": {
    "links": 3,
    "ok": 1,
    "caution": 0,
    "broken": 1,
    "pending": 1
  },
  "completed_at": null
}
```

</details>

This endpoint is used to check a collection of links, such as those from a
webpage. It will create a resource that can be checked to get the status of
the batch, as well as return the resource in the response of this request.

### JSON Attributes

- `uris` *(required)*
  - An array of URIs to be checked (max length: 5000)
- `checked_within` *(optional, defaults to 86400)*
  - An integer value of the number of seconds in the past that checks for links
    are valid.
  - Use 0 to ensure links are all checked again
- `priority` *(optional, defaults to high)*
  - A value of "high" or "low" to indicate the priority of your job
  - If you are running a lots of batches you should set this to "low" so that
    you don't block usage for in app usage.
- `webhook_uri` *(optional)*
  - A URL that will be requested once the batch is complete.
- `webhook_secret_token` *(optional)*
  - A token that will be used to generate a [HMAC-SHA1][hmac-sha1] token that
    is included with the webhook for validating the origin.

### Returns

A [`BatchReport`](#batchreport-entity), status code will be 202 for an in-progress
BatchReport and 201 for a completed one.

## `GET /batch/:id`

<details>
  <summary>Example usage</summary>

```
$ curl -s http://link-checker-api.dev.gov.uk/batch/137125 | jq
{
  "id": 137125,
  "status": "completed",
  "links": [
    {
      "uri": "https://www.gov.uk/",
      "status": "ok",
      "checked": "2017-04-12T18:47:16Z",
      "errors": {},
      "warnings": {}
    },
    {
      "uri": "https://www.gov.uk/404",
      "status": "broken",
      "checked": "2017-04-12T16:30:39Z",
      "errors": {
        "404 error (page not found)": [
          "Received 404 response from the server."
        ]
      },
      "warnings": {}
    },
    {
      "uri": "https://www.gov.uk/search",
      "status": "ok",
      "checked": "2017-04-12T18:55:29Z",
      "errors": {},
      "warnings": {}
    }
  ],
  "totals": {
    "links": 3,
    "ok": 2,
    "caution": 0,
    "broken": 1,
    "pending": 0
  },
  "completed_at": "2017-04-12T18:55:29Z"
}
```

</details>

This endpoint is used to check on the progress of a batch or to access
a completed batch

### Path Parameters

- `id` *(required)*
  - The id of a batch created via [`POST /batch`](#post-batch)

### Returns

A [`BatchReport`](#batchreport-entity)

## Batch complete webhook

You can specify a `webhook_uri` to [`POST /batch`](#post-batch) to receive a
callback when a batch is completed. This URL will receive a
`BatchReport`(#batchreport-entity) in a JSON POST request.

To use it you will need an endpoint available in your application that is
accessible without authentication and can receive POST requests.

### Verifying the webhook request

If you specified a `webhook_secret_token` when calling
[`POST /batch`](#post-batch) you will receive an additional header with the
webhook request of `X-LinkCheckerApi-Signature`. The value of this will be
a [HMAC-SHA1][hmac-sha1] signature that can be used to verify the request.

You can create one in a Rails application, using the raw JSON as the
`request_body`:

```
OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret_token, request_body)
```

And verify this matches the value in the header.

## LinkReport entity

<details>
  <summary>Example</summary>

```
{
  "uri": "https://www.gov.uk/",
  "status": "ok",
  "checked": "2017-04-12T18:47:16Z",
  "errors": {},
  "warnings": {}
}
```

</details>

### Attributes

- `uri`
  - The URI that was checked
- `status`
  - Can be the following values:
    - "pending" - A check is queued or in progress for this link
    - "ok" - The check is completed and there were no issues found with the
      link
    - "caution" - There were warnings detected for this link but no errors, an
      end user should apply caution when linking to it.
    - "broken" - There were errors detected for this link, an end user should
      not link to it.
- `checked`
  - An [RFC 3339][rfc-3339] formatted timestamp, will be `null` for a link with a
    `status` of "pending".
- `errors`
 - An object of keys to arrays of strings.
 - A key represents the short description of the error, whereas the array of
  strings details each individual problem found. Normally they'll be one value,
  but there could be more for complicated links.
 - These are designed to be presentable to an end user.
- `warnings`
 - An object of keys to arrays of strings.
 - A key represents the short description of the warning, whereas the array of
  strings details each individual problem found. Normally they'll be one value,
  but there could be more for complicated links.
 - These are designed to be presentable to an end user.

## BatchReport entity

<details>
  <summary>Example</summary>

```
{
  "id": 137125,
  "status": "completed",
  "links": [
    {
      "uri": "https://www.gov.uk/",
      "status": "ok",
      "checked": "2017-04-12T18:47:16Z",
      "errors": {},
      "warnings": {}
    },
    {
      "uri": "https://www.gov.uk/404",
      "status": "broken",
      "checked": "2017-04-12T16:30:39Z",
      "errors": {
        "404 error (page not found)": [
          "Received 404 response from the server."
        ]
      },
      "warnings": {}
    },
    {
      "uri": "https://www.gov.uk/search",
      "status": "ok",
      "checked": "2017-04-12T18:55:29Z",
      "errors": {},
      "warnings": {}
    }
  ],
  "totals": {
    "links": 3,
    "ok": 2,
    "caution": 0,
    "broken": 1,
    "pending": 0
  },
  "completed_at": "2017-04-12T18:55:29Z"
}
```

</details>

### Attributes

- `id`
  - The id of the batch this is associated with.
- `status`
  - A value of "in_progress" or "completed", indicating whether all links have
    been checked.
- `links`
  - A collection of [`LinkReports`](#linkreport-entity)
- `totals`
  - An object with numbers summarising the link progress. Contains the
    following keys:
    - `links` - The total number of links for this batch
    - `ok` - The number of links with a status of "ok"
    - `caution` - The number of links with a status of "caution"
    - `broken` - The number of links with a status of "broken"
    - `pending` - The number of links with a status of "pending"
- `completed_at`
  - An [RFC 3339][rfc-3339] formatted timestamp if this batch has a status of
    "completed" otherwise null.

[hmac-sha1]: https://en.wikipedia.org/wiki/Hash-based_message_authentication_code
[rfc-3339]: https://www.ietf.org/rfc/rfc3339.txt
