require 'rails_helper'

RSpec.describe 'Public visual base (TICKET-0082)' do
  let(:root) { Rails.root }

  # Rendered only inside the Admin/Gestor, whose Tailwind build keeps the default spacing scale.
  let(:admin_only) do
    %w[toast_component empty_state_component form_section_component status_badge_component admin_table_component
       preview_panel_component csv_import_status_component]
  end

  let(:public_sources) do
    Dir[root.join('{app/views,app/components,engines/*/app/views}/**/*.{erb,rb}')].reject do |path|
      path.match?(%r{/(admin|gestor|active_admin)/|layouts/active_admin}) || admin_only.any? { path.include?(_1) }
    end
  end

  # config/tailwind.config.js spacing: 0 1 2 3 4 6 8 12 16 — anything else is not generated for public pages.
  let(:off_scale) do
    %r{(?<![\w-])-?(?:[a-z-]+:)*
       (?:h|w|min-w|min-h|max-h|size|p[xytrblse]?|m[xytrblse]?|gap(?:-[xy])?|top|left|right|bottom|inset)
       -(?:0\.5|1\.5|2\.5|3\.5|5|7|9|10|11|14|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96)(?![\w./-])}x
  end

  it 'keeps public templates on the public spacing scale' do
    offenders = public_sources.flat_map do |path|
      File.read(path).scan(off_scale).map { "#{path.delete_prefix("#{root}/")}: #{_1}" }
    end
    expect(offenders).to be_empty
  end

  it 'uses font-sans, never the admin-only font-body, in public templates' do
    expect(public_sources.select { File.read(_1).match?(/\bfont-body\b/) }).to be_empty
  end

  it 'draws a visible focus ring on every public control' do
    css = root.join('app/assets/tailwind/application.css').read
    expect(css).to match(/:focus-visible \{\s*@apply outline-2 outline-offset-2 outline-ink;/)
    expect(css).to match(/:is\(header, \.bg-pitch, \.bg-night\) :focus-visible \{\s*@apply outline-white;/)
  end

  it 'builds public inputs from one white, graphite-bordered, 48px control' do
    helper = Class.new { include FormControlHelper }.new
    expect(helper.form_control_classes.split).to include('min-h-12', 'bg-white', 'border-graphite',
                                                         'focus-visible:outline-pitch')
    expect(helper.form_control_classes(invalid: true).split).to include('border-2', 'border-ink')
  end
end
