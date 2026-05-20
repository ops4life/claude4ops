#!/usr/bin/env node

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const pluginJsonPath = path.join(__dirname, '../../.claude-plugin/plugin.json');
const scriptPath = path.join(__dirname, '../../.github/update-plugin-version.js');

const original = fs.readFileSync(pluginJsonPath, 'utf8');
let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ok: ${name}`);
    passed++;
  } catch (err) {
    console.error(`  FAIL: ${name}`);
    console.error(`    ${err.message}`);
    failed++;
  } finally {
    fs.writeFileSync(pluginJsonPath, original);
  }
}

test('updates version in plugin.json', () => {
  execSync(`node ${scriptPath}`, { env: { ...process.env, NEXT_RELEASE_VERSION: '9.9.9' } });
  const updated = JSON.parse(fs.readFileSync(pluginJsonPath, 'utf8'));
  assert.strictEqual(updated.version, '9.9.9', `expected 9.9.9, got ${updated.version}`);
});

test('preserves other plugin.json fields', () => {
  execSync(`node ${scriptPath}`, { env: { ...process.env, NEXT_RELEASE_VERSION: '1.2.3' } });
  const updated = JSON.parse(fs.readFileSync(pluginJsonPath, 'utf8'));
  assert.ok(updated.name, 'name field missing');
  assert.ok(updated.description, 'description field missing');
  assert.ok(updated.author, 'author field missing');
});

test('exits non-zero when NEXT_RELEASE_VERSION missing', () => {
  const env = { ...process.env };
  delete env.NEXT_RELEASE_VERSION;
  let threw = false;
  try {
    execSync(`node ${scriptPath}`, { env, stdio: 'pipe' });
  } catch {
    threw = true;
  }
  assert.ok(threw, 'expected non-zero exit when env var missing');
});

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
