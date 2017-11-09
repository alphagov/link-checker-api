require 'rails_helper'

# rubocop:disable BlockLength
RSpec.describe HistoricalLinkChecker do
  subject { described_class.new(uri, checks).call }
  let(:uri) { 'https://gov.uk' }
  let(:checks) { [] }
  let(:report) { LinkChecker::UriChecker::Report.new }

  def check_without_errors(completed_at)
    double(link_errors: [], completed_at: completed_at)
  end

  def check_with_errors(completed_at)
    double(
      problem_summary: I18n.t(:page_not_found),
      link_errors: [I18n.t('page_was_not_found.singular')],
      completed_at: completed_at
    )
  end

  context 'when a link has never been checked before' do
    before do
      allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
    end

    it { is_expected.to eq(report) }

    it "should pass uri to LinkChecker" do
      expect(LinkChecker).to receive(:new).with(uri).and_call_original

      subject
    end

    context 'but it has an error' do
      let(:report) do
        LinkChecker::UriChecker::Report.new.add_problem(TestError::PageNotFound.new(from_redirect: false))
      end

      it { is_expected.to eq(report) }
      its(:errors) { is_expected.to be_present }
    end
  end

  context 'when a link has never had an error' do
    before do
      allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
    end

    let(:checks) do
      [
        check_without_errors(1.day.ago),
        check_without_errors(3.days.ago),
        check_without_errors(5.days.ago),
        check_without_errors(9.days.ago)
      ]
    end

    it { is_expected.to eq(report) }
  end

  context 'when a link currently has error' do
    let(:report) do
      LinkChecker::UriChecker::Report.new.add_problem(
        TestError::PageNotFound.new(from_redirect: false)
      )
    end

    context 'but yesterdays check was ok and so was the day before' do
      before do
        allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
      end

      let(:checks) do
        [
          check_without_errors(1.day.ago),
          check_without_errors(3.days.ago),
          check_with_errors(5.days.ago),
          check_with_errors(9.days.ago)
        ]
      end

      it { is_expected.to eq(report) }
    end

    context 'but yesterdays check was ok thought the day before was not' do
      before do
        allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
      end

      let(:checks) do
        [
          check_without_errors(1.day.ago),
          check_with_errors(3.days.ago),
          check_without_errors(5.days.ago),
          check_without_errors(9.days.ago)
        ]
      end

      it { is_expected.to eq(report) }
    end

    context 'and the same error has occurred for 3 days' do
      before do
        allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
      end

      let(:recurring_error) { I18n.t(:recurring_error, problem: I18n.t(:page_not_found)) }
      let(:recurring_error_message) do
        I18n.t(:recurred_for_more_than_three_days, problem_message: I18n.t('page_was_not_found.singular'))
      end

      let(:checks) do
        [
          check_with_errors(1.days.ago),
          check_with_errors(3.days.ago),
          check_without_errors(5.days.ago),
          check_without_errors(9.days.ago)
        ]
      end

      its(:problem_summary) { is_expected.to eq(recurring_error) }
      its(:errors) { is_expected.to include(recurring_error_message) }
    end

    context 'and the same error has occurred for 8 days' do
      before do
        allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
      end

      let(:persistent_error) { I18n.t(:recurring_error, problem: I18n.t(:page_not_found)) }
      let(:persistent_error_message) do
        I18n.t(:recurred_for_more_than_one_week, problem_message: I18n.t('page_was_not_found.singular'))
      end

      let(:checks) do
        [
          check_with_errors(1.days.ago),
          check_with_errors(3.days.ago),
          check_with_errors(6.days.ago),
          check_with_errors(8.days.ago)
        ]
      end

      its(:problem_summary) { is_expected.to eq(persistent_error) }
      its(:errors) { is_expected.to include(persistent_error_message) }
    end
  end
end
# rubocop:enable BlockLength
