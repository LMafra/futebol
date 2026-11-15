// Tokens from docs/design/0001-direction.md ("Placar de Domingo"), spec-v2 §4.
// 60-30-10: paper (base) · pitch (structure) · cartola (single accent, ≤10% of any screen).
// win/draw/loss are 15% tints only — always paired with the V/E/D glyph, never color alone.
module.exports = {
  content: [
    './app/views/**/*.{erb,html}',
    './app/components/**/*.{rb,erb}',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './spec/components/previews/**/*.rb',
    './engines/*/app/views/**/*.{erb,html}'
  ],
  theme: {
    colors: {
      paper: '#F4F1EA', pitch: '#0B6B3A', cartola: '#E85D04', ink: '#161616',
      graphite: '#4A4A45', rule: '#D9D3C4', night: '#0E1A13', white: '#FFFFFF', transparent: 'transparent',
      win: 'rgb(11 107 58 / 0.15)', draw: 'rgb(138 133 119 / 0.15)', loss: 'rgb(164 22 26 / 0.15)',
      'loss-solid': '#A4161A'
    },
    fontFamily: {
      display: ['Fraunces', 'Bitter', 'Georgia', 'serif'],
      sans: ['"Source Sans 3"', '"IBM Plex Sans"', 'system-ui', 'sans-serif']
    },
    spacing: { 0: '0', 1: '4px', 2: '8px', 3: '12px', 4: '16px', 6: '24px', 8: '32px', 12: '48px', 16: '64px' },
    borderRadius: { none: '0', sm: '4px', md: '8px', lg: '16px' },
    boxShadow: { none: 'none', sm: '0 1px 2px rgb(22 22 22 / .06)', md: '0 2px 6px rgb(22 22 22 / .08)' },
    transitionDuration: { fast: '120ms', base: '150ms', slow: '180ms' },
    transitionTimingFunction: { editorial: 'cubic-bezier(.2,.8,.2,1)' },
    extend: { gridTemplateColumns: { admin: 'repeat(12, minmax(0, 1fr))' } }
  }
}
