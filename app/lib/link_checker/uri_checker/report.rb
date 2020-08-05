module LinkChecker::UriChecker
  class Report
    attr_reader :problems

    def initialize(problems: nil)
      @problems = problems || []
    end

    def merge(other)
      @problems = problems + other.problems
      sort_problems!
      self
    end

    def add_problem(problem)
      @problems << problem
      sort_problems!
      self
    end

    def has_errors?
      errors.any?
    end

    def warnings
      problems
        .select { |problem| problem.type == :warning }
        .map(&:message)
        .uniq
    end

    def errors
      problems
        .select { |problem| problem.type == :error }
        .map(&:message)
        .uniq
    end

    def problem_summary
      problems.any? ? problems.first.summary : nil
    end

    def suggested_fix
      problems.count == 1 ? problems.first.suggested_fix : nil
    end

  private

    def sort_problems!
      @problems.sort_by! { |problem| [problem.type == :error ? 0 : 1, problem.priority] }
    end
  end
end
