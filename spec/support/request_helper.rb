module RequestHelper
  def build_link_report(params)
    {
      "uri"       => params.fetch(:uri, anything),
      "status"    => params.fetch(:status, "pending"),
      "checked"   => params.fetch(:checked, anything),
      "errors"    => params.fetch(:errors, {}),
      "warnings"  => params.fetch(:warnings, {}),
    }
  end

  def build_batch_request(params)
    {
      uris: params.fetch(:uris, ["https://www.gov.uk"]),
      checked_within: params[:checked_within],
      webhook_uri: params[:webhook_uri],
      webhook_secret_token: params[:webhook_secret_token],
    }
  end

  def build_batch_report(params)
    links = params.fetch(:links, [{ uri: "http://www.example.com" }])
      .map { |link| build_link_report(link) }

    totals = {
      "links"   => links.count,
      "ok"      => links.count { |link| link["status"] == "ok" },
      "caution" => links.count { |link| link["status"] == "caution" },
      "broken"  => links.count { |link| link["status"] == "broken" },
      "pending" => links.count { |link| link["status"] == "pending" },
    }

    {
      "id"           => params.fetch(:id, kind_of(Integer)),
      "status"       => params.fetch(:status, "in_progress"),
      "completed_at" => params.fetch(:completed_at, anything),
      "totals"       => totals,
      "links"        => links,
    }
  end
end
