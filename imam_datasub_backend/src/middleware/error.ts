import type { NextFunction, Request, Response } from 'express';

export class ApiError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code = 'API_ERROR'
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

/**
 * Express error handler middleware. Must be registered LAST, after all other
 * middleware and routes. Catches any error thrown in route handlers or passed
 * via next(error) in middleware.
 *
 * Logs errors for debugging in development/staging. In production, logs are
 * visible in Railway/container logs for post-incident debugging.
 */
export function errorHandler(
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
) {
  // Log the full error stack for debugging
  if (process.env.NODE_ENV !== 'production') {
    console.error('Error caught by handler:', error);
  } else {
    // In production, still log to container stdout/stderr for Railway
    if (error instanceof Error) {
      console.error('Error:', error.message);
      console.error('Stack:', error.stack);
    } else {
      console.error('Unknown error:', error);
    }
  }

  // Handle ApiError (our custom application errors)
  if (error instanceof ApiError) {
    return res.status(error.statusCode).json({
      status: false,
      message: error.message,
      code: error.code
    });
  }

  // Handle Zod validation errors (from request body parsing)
  if (error instanceof Error && error.name === 'ZodError') {
    return res.status(422).json({
      status: false,
      message: 'Request validation failed',
      code: 'VALIDATION_ERROR',
      details: (error as any).errors
    });
  }

  // Handle generic errors
  const message = error instanceof Error ? error.message : 'Unexpected server error';
  const statusCode = (error as any)?.statusCode || 500;

  return res.status(statusCode).json({
    status: false,
    message
  });
}
