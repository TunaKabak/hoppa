import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "default_super_secret_for_dev_mode";
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || JWT_SECRET;

const JWT_ACCESS_EXPIRES_IN = process.env.JWT_ACCESS_EXPIRES_IN || "15m";
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || "30d";

export interface TokenPayload {
  id?: string;
  role?: string;
  type?: "access" | "refresh" | "handshake";
  tokenId?: string;
  iat?: number;
  exp?: number;
}

export class JwtUtils {
  /**
   * Kısa ömürlü Access Token üretir (Varsayılan 15 dakika)
   */
  public static generateAccessToken(userId: string, role: string): string {
    return jwt.sign(
      { id: userId, role: role, type: "access" },
      JWT_SECRET,
      { expiresIn: JWT_ACCESS_EXPIRES_IN as jwt.SignOptions["expiresIn"] }
    );
  }

  /**
   * Geriye dönük uyumluluk için alias: generateAccessToken çağırır
   */
  public static generateToken(userId: string, role: string): string {
    return this.generateAccessToken(userId, role);
  }

  /**
   * Uzun ömürlü Refresh Token üretir (Varsayılan 30 gün)
   */
  public static generateRefreshToken(userId: string, role: string, tokenId: string): string {
    return jwt.sign(
      { id: userId, role: role, tokenId: tokenId, type: "refresh" },
      JWT_REFRESH_SECRET,
      { expiresIn: JWT_REFRESH_EXPIRES_IN as jwt.SignOptions["expiresIn"] }
    );
  }

  /**
   * Misafir el sıkışma (handshake) token'ı üretir (5 dakika)
   */
  public static generateHandshakeToken(): string {
    return jwt.sign(
      { type: "handshake" },
      JWT_SECRET,
      { expiresIn: "5m" }
    );
  }

  /**
   * Access Token doğrular
   */
  public static verifyAccessToken(token: string): TokenPayload | null {
    try {
      const decoded = jwt.verify(token, JWT_SECRET) as TokenPayload;
      return decoded;
    } catch (error) {
      return null;
    }
  }

  /**
   * Geriye dönük uyumluluk için alias
   */
  public static verifyToken(token: string): TokenPayload | null {
    return this.verifyAccessToken(token);
  }

  /**
   * Refresh Token doğrular
   */
  public static verifyRefreshToken(token: string): TokenPayload | null {
    try {
      const decoded = jwt.verify(token, JWT_REFRESH_SECRET) as TokenPayload;
      if (decoded.type !== "refresh") {
        return null;
      }
      return decoded;
    } catch (error) {
      return null;
    }
  }
}
