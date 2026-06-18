// Plugin-specific ESLint config. The shared rules/blocks live in
// eslint.shared.cjs (synced across plugins). This plugin has no extra globals
// or ignores, so it just invokes the factory with defaults.
module.exports = require('./eslint.shared.cjs')();
