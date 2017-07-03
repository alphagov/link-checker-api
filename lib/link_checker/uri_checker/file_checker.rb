module LinkChecker::UriChecker
  class FileChecker < Checker
    def call
      add_error(
        summary: I18n.t(:not_available_online),
        message: {
          singular: I18n.t("links_to_file_on_computer.singular"),
          redirect: I18n.t("links_to_file_on_computer.redirect"),
        }
      )
    end
  end
end
