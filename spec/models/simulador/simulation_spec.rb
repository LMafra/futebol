require 'rails_helper'

RSpec.describe Simulador::Simulation do
  def parse(raw) = described_class.parse(raw, championship_id: 1, editable_ids: [10, 11])

  it 'keeps integer guesses for open matches and skips the blank ones' do
    simulation = parse('10' => { 'home' => '2', 'away' => '0' }, '11' => { 'home' => '', 'away' => '' })

    expect(simulation).to be_valid
    expect(simulation.guesses).to eq(10 => { home: 2, away: 0 })
  end

  it 'flags half-filled, negative or non-numeric scores per match' do
    simulation = parse('10' => { 'home' => '1', 'away' => '' }, '11' => { 'home' => '-1', 'away' => 'x' })

    expect(simulation).not_to be_valid
    expect(simulation.errors.keys).to eq(%w[10 11])
    expect(simulation.guesses).to be_empty
  end

  it 'rejects matches that are not open in the championship' do
    simulation = parse('99' => { 'home' => '1', 'away' => '0' })

    expect(simulation.errors).to eq('99' => 'não é uma partida em aberto deste campeonato')
  end
end
