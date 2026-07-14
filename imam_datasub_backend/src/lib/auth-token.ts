import crypto from 'node:crypto';
import { env } from '../config/env.js';
import { ApiError } from '../middleware/error.js';

type TokenType = 'access' | 'refresh';

type TokenPayload = {
  sub: string;
  email: string;
  type: TokenType;
  exp: number;
  iat: number;
};

function base64Url(input: string | Buffer) {
  return Buffer.from(input).toString('base64url');
}

function sign(data: string) {
  return crypto
    .createHmac('sha256', env.AUTH_TOKEN_SECRET)
    .update(data)
    .digest('base64url');
}

export function createAuthToken(params: {
  userId: string;
  email: string;
  type: TokenType;
  ttlSeconds: number;
}) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payload = base64Url(
    JSON.stringify({
      sub: params.userId,
      email: params.email,
      type: params.type,
      iat: now,
      exp: now + params.ttlSeconds
    } satisfies TokenPayload)
  );
  const unsigned = `${header}.${payload}`;
  return `${unsigned}.${sign(unsigned)}`;
}

export function verifyAuthToken(token: string, expectedType: TokenType) {
  const [header, payload, signature] = token.split('.');
  if (!header || !payload || !signature) {
    throw new ApiError(401, 'Invalid auth token', 'INVALID_TOKEN');
  }

  const unsigned = `${header}.${payload}`;
  const expected = sign(unsigned);
  const actualBuffer = Buffer.from(signature);
  const expectedBuffer = Buffer.from(expected);
  if (
    actualBuffer.length !== expectedBuffer.length ||
    !crypto.timingSafeEqual(actualBuffer, expectedBuffer)
  ) {
    throw new ApiError(401, 'Invalid auth token', 'INVALID_TOKEN');
  }

  const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as TokenPayload;
  if (decoded.type !== expectedType) {
    throw new ApiError(401, 'Invalid token type', 'INVALID_TOKEN_TYPE');
  }
  if (!decoded.exp || decoded.exp < Math.floor(Date.now() / 1000)) {
    throw new ApiError(401, 'Auth token expired', 'TOKEN_EXPIRED');
  }

  return decoded;
}

export function authTokensFor(user: { id: string; email: string }) {
  return {
    accessToken: createAuthToken({
      userId: user.id,
      email: user.email,
      type: 'access',
      ttlSeconds: env.ACCESS_TOKEN_TTL_SECONDS
    }),
    refreshToken: createAuthToken({
      userId: user.id,
      email: user.email,
      type: 'refresh',
      ttlSeconds: env.REFRESH_TOKEN_TTL_SECONDS
    }),
    expiresIn: env.ACCESS_TOKEN_TTL_SECONDS
  };
}
