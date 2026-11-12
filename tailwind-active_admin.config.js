import { execSync } from 'child_process';

// Always use the last line of output since Bundler's DEBUG env will print additional lines.
const activeAdminPath = execSync('bundle show activeadmin', { encoding: 'utf-8' }).trim().split(/\r?\n/).pop();

// Standalone Tailwind (tailwindcss-rails) has no node_modules: load the plugin shipped inside the gem.
const { default: activeAdminPlugin } = await import(`${activeAdminPath}/plugin.js`);

export default {
  content: [
    `${activeAdminPath}/vendor/javascript/flowbite.js`,
    `${activeAdminPath}/plugin.js`,
    `${activeAdminPath}/app/views/**/*.{arb,erb,html,rb}`,
    './app/admin/**/*.{arb,erb,html,rb}',
    './app/views/active_admin/**/*.{arb,erb,html,rb}',
    './app/views/admin/**/*.{arb,erb,html,rb}',
    './app/views/gestor/**/*.{arb,erb,html,rb}',
    './app/components/**/*.{rb,erb}',
    './app/helpers/admin_helper.rb',
    './app/helpers/admin_icons_helper.rb',
    './app/helpers/championship_wizard_helper.rb',
    './app/views/layouts/active_admin*.{erb,html}',
    './app/javascript/**/*.js'
  ],
  // Editorial light admin only: AA's dark_mode_toggle.js adds `.dark` from the OS preference,
  // so `dark:` variants must target a selector the app never renders.
  darkMode: ["selector", "[data-theme=never]"],
  plugins: [
    activeAdminPlugin
  ]
}
