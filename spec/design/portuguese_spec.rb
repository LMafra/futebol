require 'rails_helper'
require 'ripper'

# docs/glossary.md: a interface fala português. Scout é nome interno (o texto diz Lance ou Estatísticas), e
# Status, Preview, Ranking e Log têm termo próprio. E-mail, CSV e PWA ficam como estão.
RSpec.describe 'Interface só em português' do
  english = /\b(?:status|preview|scouts?|rankings?|logs?)\b/i
  hidden_attributes = /\b(?:class|id|for|name|type|role|href|src|datetime|form|method|action|rel|target|value|
                         autocomplete|inputmode|pattern|aria-(?:labelledby|describedby|controls|hidden|current|
                         live|sort|expanded|pressed)|data-[\w-]+)="[^"]*"?/x
  sql = /\b(?:SELECT|WHERE|UPDATE|INSERT|JOIN|ORDER BY|IS NULL|IS NOT)\b|\w+ (?:=|IN|<>) /
  ruby_sources = Rails.root.glob('{app,engines/*/app}/{admin,components,controllers,forms,helpers,services}/**/*.rb') +
                 Rails.root.glob('lib/admin_*.rb')
  templates = Rails.root.glob('{app,engines/*/app}/{views,components}/**/*.erb')

  # Exception messages are for developers.
  string_literals = lambda do |ruby|
    lines = ruby.lines
    Ripper.lex(ruby).filter_map do |((line, _), type, token)|
      token if type == :on_tstring_content && !lines[line - 1].match?(/\braise\b/)
    end
  end
  # Prose (with a space) or a capitalized word; identifiers, paths and keys are code.
  prose = ->(token) { token.match?(/\s|\A\p{Lu}/) && !token.match?(sql) }
  visible = lambda do |chunk|
    chunk = chunk.gsub(hidden_attributes, ' ')
    labels = chunk.scan(/(?:aria-label|title|placeholder|alt)="([^"]*)/).flatten
    [chunk.gsub(/<[^>]*>?/, ' '), *labels]
  end
  report = ->(path, texts) { texts.grep(english).map { "#{path.relative_path_from(Rails.root)}: #{_1.squish}" } }

  it 'keeps English terms out of the templates' do
    offenders = templates.flat_map do |path|
      ruby = ActionView::Template::Handlers::ERB::Erubi.new(path.read).src
      report.call(path, string_literals.call(ruby).flat_map { |token| prose.call(token) ? visible.call(token) : [] })
    end

    expect(offenders).to be_empty, offenders.join("\n")
  end

  it 'keeps English terms out of the labels and messages in Ruby' do
    offenders = ruby_sources.flat_map { |path| report.call(path, string_literals.call(path.read).select(&prose)) }

    expect(offenders).to be_empty, offenders.join("\n")
  end

  it 'keeps English terms out of the pt-BR locales' do
    values = ->(node) { node.is_a?(Hash) ? node.values.flat_map(&values) : Array(node).grep(String) }
    locales = Rails.root.glob('{config,engines/*/config}/locales/**/*.yml')
    offenders = locales.flat_map { |path| report.call(path, values.call(YAML.load_file(path, aliases: true))) }

    expect(offenders).to be_empty, offenders.join("\n")
  end
end
