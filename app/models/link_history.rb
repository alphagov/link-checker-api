class LinkHistory < ApplicationRecord
  belongs_to :link

  def add_errors(errors)
    link_errors.keep_if { |link_error| errors.include?(link_error[:message]) }

    errors.each { |error| add_error(error) }
  end

  def add_error(message)
    return if link_errors.any? { |error| error[:message] == message }

    link_errors << {
      message: message,
      started_at: DateTime.now
    }

    save
  end

  def clear_errors
    update!(link_errors: [])
  end
end
