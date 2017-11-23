class LinkHistory < ApplicationRecord
  belongs_to :link

  #To do: store link warnings
  def update_errors(errors)
    remove_resolved_errors(errors)
    errors.each { |error| add_error(error) }
  end

  def add_error(message)
    return if error_exists?(message)

    link_errors << {
      message: message,
      started_at: DateTime.now
    }

    save
  end

  def clear_errors
    update!(link_errors: [])
  end

private

  def remove_resolved_errors(errors)
    link_errors.keep_if { |link_error| errors.include?(link_error[:message]) }
  end

  def error_exists?(message)
    link_errors.any? { |error| error[:message] == message }
  end
end
