import * as functions from "firebase-functions";
import express from "express";
const cors = require("cors");
import businessAuth from "./api/business/auth";
import businessAdmin from "./api/business/admin";
import consumerAuth from "./api/consumer/auth";

const app = express();

// Automatically allow cross-origin requests
app.use(cors({ origin: true }));

// Body parser middleware
app.use(express.json());

// API Routes
app.use("/api/business/auth", businessAuth);
app.use("/api/business/admin", businessAdmin);
app.use("/api/consumer/auth", consumerAuth);

// Export the express app as a single Firebase Cloud Function named 'api'
export const api = functions.https.onRequest(app);
