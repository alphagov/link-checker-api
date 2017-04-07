class CheckPresenter
  def initialize(check)
    @check = check
  end

  def call
    {
      uri: check.link.uri,
      status: check.status.to_s,
      checked: check.completed_at.try(:iso8601),
      errors: check.link_errors,
      warnings: check.link_warnings,
    }.deep_symbolize_keys
  end

private

  attr_reader :check
end
