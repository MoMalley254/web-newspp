import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { JwtPayload } from '../../types/admin/adminTypes'; 

export const authenticateAccessToken = (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers['authorization'];
  const token = authHeader?.split(' ')[1]; 

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('JWT_SECRET is not defined in environment variables.');
    }

    const payload = jwt.verify(token, secret) as JwtPayload;
    req.user = payload; // Attach user data to request for use in controllers

    next();
  } catch (err) {
    return res.status(403).json({ message: 'Invalid or expired token' });
  }
}