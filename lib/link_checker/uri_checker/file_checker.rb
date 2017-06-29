module LinkChecker::UriChecker
  class FileChecker < Checker
    def call
      report.add_problem(PROBLEM)
    end

  private

    PROBLEM = Problem.new(:error, 0, "Not available online", "This links to a file on your computer - users won't be able to access it online.", "Find an online version of your file.")
  end
end
