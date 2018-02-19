# Link Checker API's Monitoring Functionality.

This documents the link monitoring capabilities of the Link Checker API. This is in edition to the endpoints detailed in the [API documentation](./api.md).

### Contents

- [Service Classes](#service-classes)
- [Workers](#workers)

## Service Classes

### LinkMonitor::CheckMonitoredLinks

This class creates, updates, or clears down the error history for a particular link.

Once a link has a history, addition information will be added to the returned errors array in (`CheckPresenter`)[https://github.com/alphagov/link-checker-api/blob/master/app/presenters/check_presenter.rb] this will be present in any individual link checks or batch checks.

e.g. If a link has been experiencing a 404 error since 23/12/17 an on demand check will show this.

```js
{
  ...
  "links": [
    {
      "uri": "https://www.gov.uk/404",
      "status": "broken",
      "checked": "2017-04-12T16:30:39Z",
      "errors": [
        "Received 404 response from the server since 23/12/17"
      ],
      "warnings": [],
      "problem_summary": "404 error (page not found)",
      "suggested_fix": ""
    }
  ],
  ...
}
```

### LinkMonitor::UpsertResourceMonitor

This class creates, or updates any links associated to a resource monitor. It does this based on the unique combination of `app` and `reference` that are passed into it via the monitor endpoint.

When updating, if a new link has been added to the collection, it creates any required records and associations. However when a link is removed it only destroys the joining (`MonitorLink`)[https://github.com/alphagov/link-checker-api/blob/master/app/models/monitor_link.rb] in case the link is used buy any other monitors, therefore persisting the error history.

## Workers

### ScheduleResourceMonitorWorker

A scheduled job that runs at 1 a.m. every night, it queues up [ResourceMonitorWorkers](https://github.com/alphagov/link-checker-api/blob/master/app/workers/resource_monitor_worker.rb) for each enabled [ResourceMonitor](https://github.com/alphagov/link-checker-api/blob/master/app/models/resource_monitor.rb)

### ResourceMonitorWorker

A standalone job that uses [LinkMonitor::CheckMonitoredLinks](https://github.com/alphagov/link-checker-api/blob/master/lib/link_monitor/check_monitored_links.rb) to run [CheckWorker](https://github.com/alphagov/link-checker-api/blob/master/app/workers/check_worker.rb)
