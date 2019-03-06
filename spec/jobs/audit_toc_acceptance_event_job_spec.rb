require 'rails_helper'

RSpec.describe AuditTocAcceptanceEventJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(data) }
  let(:data) { [Time.zone.now.to_s, 'user-dsi-id', '010101'] }

  it 'queues the job' do
    expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'is in the audit_toc_acceptance_event queue' do
    expect(job.queue_name).to eq('audit_toc_acceptance_event')
  end

  it 'writes to the spreadsheet' do
    stub_const('AUDIT_SPREADSHEET_ID', 'abc1-def2')
    spreadsheet = double(:mock)
    expect(Spreadsheet::Writer).to receive(:new)
      .with('abc1-def2', AuditTocAcceptanceEventJob::WORKSHEET_POSITION).and_return(spreadsheet)
    expect(spreadsheet).to receive(:append).with(data)

    perform_enqueued_jobs { job }
  end
end
