import { env } from './config/env.js';
import { createApp } from './app.js';
import { prisma } from './lib/prisma.js';

async function startServer() {
  try {
    const app = createApp();

    const server = app.listen(env.PORT, () => {
      console.log(`✓ Imam Datasub backend listening on http://0.0.0.0:${env.PORT}`);
    });

    // Handle server errors (e.g., port already in use, bind errors)
    server.on('error', (err: NodeJS.ErrnoException) => {
      if (err.code === 'EADDRINUSE') {
        console.error(`✗ Port ${env.PORT} is already in use`);
      } else {
        console.error('✗ Server error:', err);
      }
      process.exit(1);
    });

    // Graceful shutdown on signals
    const shutdownSignals: NodeJS.Signals[] = ['SIGTERM', 'SIGINT'];
    shutdownSignals.forEach((signal) => {
      process.on(signal, async () => {
        console.log(`\nReceived ${signal}, shutting down gracefully...`);
        server.close(async () => {
          await prisma.$disconnect();
          console.log('✓ Server closed, database disconnected');
          process.exit(0);
        });

        // Force exit after 10 seconds
        setTimeout(() => {
          console.error('✗ Forced shutdown after 10s timeout');
          process.exit(1);
        }, 10_000);
      });
    });
  } catch (error) {
    console.error('✗ Failed to start server:', error);
    await prisma.$disconnect();
    process.exit(1);
  }
}

startServer();
