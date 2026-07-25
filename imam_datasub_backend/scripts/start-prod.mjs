import { spawn } from 'node:child_process';

function run(command, args) {
  return new Promise((resolve, reject) => {
    console.log(`[start] ${command} ${args.join(' ')}`);
    const child = spawn(command, args, {
      stdio: 'inherit',
      shell: process.platform === 'win32'
    });

    child.on('error', reject);
    child.on('exit', (code, signal) => {
      if (code === 0) return resolve();
      reject(new Error(`${command} exited with code ${code ?? 'null'} signal ${signal ?? 'null'}`));
    });
  });
}

process.on('uncaughtException', (error) => {
  console.error('[start] uncaught exception', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  console.error('[start] unhandled rejection', reason);
  process.exit(1);
});

console.log('[start] Running database migrations');
await run('npx', ['prisma', 'migrate', 'deploy']);

console.log('[start] Starting API server');
await import('../dist/server.js');
