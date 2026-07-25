import { spawn } from 'node:child_process';

function run(command, args) {
  return new Promise((resolve, reject) => {
    console.log(`[start] Running: ${command} ${args.join(' ')}`);
    const child = spawn(command, args, {
      stdio: 'inherit',
      shell: process.platform === 'win32'
    });

    child.on('error', (error) => {
      console.error(`[start] Failed to start process: ${error.message}`);
      reject(error);
    });

    child.on('exit', (code, signal) => {
      if (code === 0) {
        console.log(`[start] ✓ ${command} completed successfully`);
        return resolve();
      }
      
      const exitInfo = code !== null ? `code ${code}` : `signal ${signal}`;
      const errorMsg = `${command} exited with ${exitInfo}`;
      console.error(`[start] ✗ ${errorMsg}`);
      reject(new Error(errorMsg));
    });
  });
}

// Global error handlers
process.on('uncaughtException', (error) => {
  console.error('[start] ✗ Uncaught exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  console.error('[start] ✗ Unhandled rejection:', reason);
  process.exit(1);
});

async function main() {
  try {
    console.log('[start] Starting production deployment sequence...');
    console.log('[start] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    console.log('\n[start] Step 1: Running database migrations');
    await run('npx', ['prisma', 'migrate', 'deploy']);

    console.log('\n[start] Step 2: Starting API server');
    console.log('[start] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    await import('../dist/server.js');
  } catch (error) {
    console.error('[start] ✗ Deployment failed');
    console.error('[start] Error:', error instanceof Error ? error.message : error);
    console.error('[start] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    process.exit(1);
  }
}

main();
