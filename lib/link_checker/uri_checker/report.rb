module LinkChecker::UriChecker
  class Report
    attr_reader :problems

    def initialize(problems: nil)
      @problems = problems || Array.new
    end

    def merge(other, with_priority: 0)
      @problems = problems + other.problems.map { |problem| problem.with_priority(with_priority) }
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
    end

    def errors
      problems
        .select { |problem| problem.type == :error }
        .map(&:message)
    end

    def problem_summary
      problems.any? ? problems.first.summary : nil
    end

    def suggested_fix
      problems.any? ? problems.first.suggested_fix : nil
    end

  private

    def sort_problems!
      @problems.sort_by! { |problem| [problem.type == :error ? 0 : 1, problem.priority] }
    end
  end
end
