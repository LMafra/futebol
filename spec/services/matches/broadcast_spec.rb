require 'rails_helper'

RSpec.describe BroadcastUpdateService do
  include ActiveSupport::Testing::TimeHelpers

  let(:match) { create(:match, status: 'live', home_score: 1, away_score: 0) }
  let(:stream) { match.to_gid_param }

  def call_concurrently(times, match_to_broadcast = match)
    start = Concurrent::CountDownLatch.new(1)
    threads = Array.new(times) do
      Thread.new do
        start.wait
        described_class.call(match: match_to_broadcast)
      end
    end
    start.count_down
    threads.map(&:value)
  end

  it '10 threads concorrentes com a mesma match disparam exatamente 1 broadcast' do
    results = nil

    expect { results = call_concurrently(10) }.to have_broadcasted_to(stream).once
    expect(results.count(true)).to eq(1)
    expect(results.count(false)).to eq(9)
  end

  it 'grava a chave com unless_exist e expiração de 5 segundos' do
    allow(Rails.cache).to receive(:write).and_call_original

    described_class.call(match:)

    expect(Rails.cache).to have_received(:write)
      .with("broadcast:match:#{match.id}", 1, unless_exist: true, expires_in: 5.seconds)
  end

  it 'envia um turbo-stream replace do placar' do
    target = ActionView::RecordIdentifier.dom_id(match, :scoreboard)

    expect { described_class.call(match:) }
      .to(have_broadcasted_to(stream).with { |payload| expect(payload).to include('action="replace"', target) })
  end

  it 'volta a transmitir depois que a janela de 5 segundos expira' do
    described_class.call(match:)

    travel(5.seconds + 1) do
      expect { described_class.call(match:) }.to have_broadcasted_to(stream).once
    end
  end

  it 'não bloqueia partidas diferentes' do
    other = create(:match, status: 'live', home_score: 0, away_score: 0)
    described_class.call(match:)

    expect { described_class.call(match: other) }.to have_broadcasted_to(other.to_gid_param).once
  end
end
