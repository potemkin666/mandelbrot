import assert from 'node:assert/strict';
import test from 'node:test';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

const read = (file: string): string => readFileSync(resolve(root, file), 'utf8');

test('portable launcher files exist', () => {
  for (const file of [
    'RUN ME.bat',
    'STOP.bat',
    'RUN ME.sh',
    'RUN ME.command',
    'README-FIRST.txt',
    'TROUBLESHOOTING.txt',
  ]) {
    assert.ok(existsSync(resolve(root, file)), `${file} should exist`);
  }
});

test('windows launcher uses self-directory, localhost, and friendly failure handling', () => {
  const launcher = read('RUN ME.bat');
  assert.match(launcher, /cd \/d "%~dp0"/i);
  assert.match(launcher, /set "HOST=127\.0\.0\.1"/);
  assert.match(launcher, /pause/i);
  const stopLauncher = read('STOP.bat');
  assert.match(stopLauncher, /docker compose down/i);
});

test('vite config defaults to localhost and env-driven local launch settings', () => {
  const viteConfig = read('vite.config.ts');
  assert.match(viteConfig, /const wmHost = env\.WM_HOST\?\.trim\(\) \|\| '127\.0\.0\.1';/);
  assert.match(viteConfig, /const serverPort = Number\.isFinite\(wmPort\) && wmPort > 0 \? wmPort : 3000;/);
  assert.match(viteConfig, /host: wmHost,/);
  assert.match(viteConfig, /open: autoOpenBrowser,/);
});
