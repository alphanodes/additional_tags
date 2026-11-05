import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['test/javascript/**/*.test.js'],
    reporters: ['default', 'junit'],
    outputFile: { junit: 'test-results/junit.xml' },
    testTimeout: 10000
  }
});
