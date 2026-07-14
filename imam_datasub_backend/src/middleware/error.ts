import type { NextFunction, Request, Response } from 'express';

export class ApiError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code = 'API_ERROR'
  ) {
    super(message);
  }
}

export function errorHandler(
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
) {
  if (error instanceof ApiError) {
    return res.status(error.statusCode).json({
      status: false,
      message: error.message,
      code: error.code
    });
  }

  const message = error instanceof Error ? error.message : 'Unexpected server error';
  return res.status(500).json({ status: false, message });
}
