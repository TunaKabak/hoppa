"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
const functions = __importStar(require("firebase-functions"));
const express_1 = __importDefault(require("express"));
const cors = require("cors");
const auth_1 = __importDefault(require("./api/business/auth"));
const admin_1 = __importDefault(require("./api/business/admin"));
const auth_2 = __importDefault(require("./api/consumer/auth"));
const app = (0, express_1.default)();
// Automatically allow cross-origin requests
app.use(cors({ origin: true }));
// Body parser middleware
app.use(express_1.default.json());
// API Routes
app.use("/api/business/auth", auth_1.default);
app.use("/api/business/admin", admin_1.default);
app.use("/api/consumer/auth", auth_2.default);
// Export the express app as a single Firebase Cloud Function named 'api'
exports.api = functions.https.onRequest(app);
//# sourceMappingURL=index.js.map