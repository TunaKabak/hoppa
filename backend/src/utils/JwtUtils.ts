import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "default_super_secret_for_dev_mode";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";

export class JwtUtils {
  public static generateToken(userId: string, role: string): string {
    return jwt.sign(
      { id: userId, role: role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN as jwt.SignOptions["expiresIn"] }
    );
  }

  public static verifyToken(token: string): any {
    try {
      return jwt.verify(token, JWT_SECRET);
    } catch (error) {
      return null;
    }
  }
}
