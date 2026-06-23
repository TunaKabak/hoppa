const jwt = require('jsonwebtoken');

function test() {
  try {
    const JWT_SECRET = process.env.JWT_SECRET || "default_super_secret_for_dev_mode";
    const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";
    
    const token = jwt.sign(
      { id: "69a9ae92-2b72-4f83-9693-462fb3c66c5e", role: "SUPER_ADMIN" },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    console.log("Token:", token);
  } catch (e) {
    console.error(e);
  }
}
test();
