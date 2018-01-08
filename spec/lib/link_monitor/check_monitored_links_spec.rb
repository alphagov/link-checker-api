require "rails_helper"

RSpec.describe LinkMonitor::CheckMonitoredLinks do
  let(:resource_monitor) { create(:resource_monitor, number_of_links: 1) }

  subject { described_class.new(resource_monitor: resource_monitor).call }

  let(:report) do
    LinkChecker::UriChecker::Report.new.add_problem(
      TestError::PageNotFound.new(from_redirect: false)
    )
  end

  before do
    allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
  end

  context 'when no checks in the last 8 hours exists' do
    it 'should call LinkChecker' do
      expect(LinkChecker).to receive(:new).exactly(1).times.and_call_original

      subject
    end

    it 'should create a check' do
      subject

      resource_monitor.reload

      expect(resource_monitor.links.first.checks.last.problem_summary).to eq(report.problem_summary)
    end

    # rubocop:disable AmbiguousBlockAssociation
    it 'should update the monitored link' do
      expect { subject }.to change { resource_monitor.links.first.link_history.updated_at }
    end
    # rubocop:enable AmbiguousBlockAssociation
  end

  context 'when a check exists within 8 hours' do
    before do
      resource_monitor.links.first.checks.create(completed_at: 30.minutes.ago)
    end

    it 'should not call LinkChecker' do
      expect(LinkChecker).not_to receive(:new)

      subject
    end
    # rubocop:disable AmbiguousBlockAssociation
    it 'should not create another check' do
      expect { subject }.not_to change { resource_monitor.links.first.checks.count }
    end

    it 'should not update the link_history' do
      expect { subject }.not_to change { resource_monitor.links.first.link_history.updated_at }
    end
    # rubocop:enable AmbiguousBlockAssociation
  end

  context 'when there is an existing error' do
    context 'and the report comes back ok' do
      it 'should remove the error history' do
        expect(resource_monitor.links.first.link_history.link_errors).to be_empty
      end
    end

    context 'and the report comes with another error' do
      before do
        resource_monitor.links.first.link_history.add_error('SSL expired')
      end

      it 'should update the error history' do
        subject
        expect(resource_monitor.links.first.link_history.link_errors.last['message']).to include(report.errors.first)
      end
    end

    context 'and the report comes with another error' do
      before do
        resource_monitor.links.first.link_history.add_error('SSL expired')
      end

      it 'should update the error history' do
        subject
        expect(resource_monitor.links.first.link_history.link_errors.count).to eq(1)
        expect(resource_monitor.links.first.link_history.link_errors.last['message']).to eq(report.errors.first)
      end
    end

    context 'and the report comes without an errors' do
      let(:report) { LinkChecker::UriChecker::Report.new }

      before do
        allow_any_instance_of(LinkChecker).to receive(:call).and_return(report)
        resource_monitor.links.first.link_history.add_error('SSL expired')
      end

      it 'should update the error history' do
        subject
        resource_monitor.reload
        expect(resource_monitor.links.first.link_history.link_errors).to be_empty
      end
    end
  end
end
# rubocop:enable BlockLength
