export interface AdminData {
  email: string;
  name: string;
  password: string;
}

export interface JwtPayload {
  userId: string;
}

export interface RefreshTokenValidationResult {
  valid: boolean;
  userId?: string;
  error?: any;
}
