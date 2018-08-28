# frozen_string_literal: true

require 'spec_helper'

module ElasticAPM
  module Transport
    RSpec.describe Base, :mock_intake do
      let(:agent) { Agent.new Config.new }
      let(:instrumenter) { Instrumenter.new agent }

      subject { described_class.new agent.config }

      describe '#submit' do
        it 'takes records and sends them off' do
          transaction = Transaction.new instrumenter, 'T' do |t|
            t.span 'span 0' do
            end
          end

          subject.submit transaction
          subject.flush

          expect(@mock_intake.requests.length).to be 1
          expect(@mock_intake.transactions.length).to be 1

          agent.stop
        end

        it 'starts all requests with a metadata object' do
          subject.post({})
          subject.flush
          subject.post({})
          subject.flush
          expect(@mock_intake.requests.length).to be 2
          expect(@mock_intake.metadatas.length).to be 2
        end

        it 'filters sensitive data' do
          allow(subject.connection).to receive(:write) { true }

          subject.post(
            transaction: {
              id: 1,
              context: { request: { headers: { ApiKey: 'OH NO!' } } }
            }
          )

          expect(subject.connection).to have_received(:write)
        end
      end
    end
  end
end