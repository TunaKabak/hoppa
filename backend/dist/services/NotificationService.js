"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notificationService = void 0;
const app_1 = require("firebase-admin/app");
const messaging_1 = require("firebase-admin/messaging");
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
class NotificationService {
    isInitialized = false;
    constructor() {
        this.initializeFirebase();
    }
    initializeFirebase() {
        try {
            if ((0, app_1.getApps)().length === 0) {
                if (!process.env.FIREBASE_PRIVATE_KEY || !process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL) {
                    console.warn('WARNING: Firebase credentials not found, running in MOCK mode. Push notifications will be simulated.');
                    this.isInitialized = false;
                    return;
                }
                (0, app_1.initializeApp)({
                    credential: (0, app_1.cert)({
                        projectId: process.env.FIREBASE_PROJECT_ID,
                        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
                        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/^"|"$/g, '').replace(/\\n/g, '\n'),
                    }),
                });
                this.isInitialized = true;
                console.log('Firebase Admin SDK initialized successfully.');
            }
            else {
                this.isInitialized = true;
            }
        }
        catch (error) {
            console.warn('WARNING: Failed to initialize Firebase Admin SDK. Running in MOCK mode.', error);
            this.isInitialized = false;
        }
    }
    async sendToUser(userId, title, body, data) {
        try {
            const deviceTokens = await prisma.deviceToken.findMany({
                where: { userId }
            });
            if (deviceTokens.length === 0) {
                console.log(`No device tokens found for user ${userId}. Skipping notification.`);
                return;
            }
            const tokens = deviceTokens.map(dt => dt.token);
            if (!this.isInitialized) {
                console.log(`[MOCK NOTIFICATION] To: ${userId} (${tokens.length} devices) | Title: ${title} | Body: ${body}`);
                return;
            }
            const message = {
                notification: {
                    title,
                    body,
                },
                data: data || {},
                tokens: tokens,
            };
            const response = await (0, messaging_1.getMessaging)().sendEachForMulticast(message);
            console.log(`Notification sent to user ${userId}. Success count: ${response.successCount}, Failure count: ${response.failureCount}`);
            // Cleanup invalid tokens
            if (response.failureCount > 0) {
                const failedTokens = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Failed to send notification to token ${tokens[idx]}:`, resp.error);
                        const errorCode = resp.error?.code;
                        if (errorCode === 'messaging/invalid-registration-token' ||
                            errorCode === 'messaging/registration-token-not-registered') {
                            failedTokens.push(tokens[idx]);
                        }
                    }
                });
                if (failedTokens.length > 0) {
                    await prisma.deviceToken.deleteMany({
                        where: {
                            token: {
                                in: failedTokens
                            }
                        }
                    });
                    console.log(`Cleaned up ${failedTokens.length} invalid tokens for user ${userId}`);
                }
            }
        }
        catch (error) {
            console.error(`Error sending notification to user ${userId}:`, error);
        }
    }
    async sendToMerchant(merchantId, title, body, data) {
        try {
            const deviceTokens = await prisma.deviceToken.findMany({
                where: { merchantId }
            });
            if (deviceTokens.length === 0) {
                console.log(`No device tokens found for merchant ${merchantId}. Skipping notification.`);
                return;
            }
            const tokens = deviceTokens.map(dt => dt.token);
            if (!this.isInitialized) {
                console.log(`[MOCK NOTIFICATION] To Merchant: ${merchantId} (${tokens.length} devices) | Title: ${title} | Body: ${body}`);
                return;
            }
            const message = {
                notification: {
                    title,
                    body,
                },
                data: data || {},
                tokens: tokens,
            };
            const response = await (0, messaging_1.getMessaging)().sendEachForMulticast(message);
            console.log(`Notification sent to merchant ${merchantId}. Success count: ${response.successCount}, Failure count: ${response.failureCount}`);
            // Cleanup invalid tokens
            if (response.failureCount > 0) {
                const failedTokens = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Failed to send notification to merchant token ${tokens[idx]}:`, resp.error);
                        const errorCode = resp.error?.code;
                        if (errorCode === 'messaging/invalid-registration-token' ||
                            errorCode === 'messaging/registration-token-not-registered') {
                            failedTokens.push(tokens[idx]);
                        }
                    }
                });
                if (failedTokens.length > 0) {
                    await prisma.deviceToken.deleteMany({
                        where: {
                            token: {
                                in: failedTokens
                            }
                        }
                    });
                    console.log(`Cleaned up ${failedTokens.length} invalid tokens for merchant ${merchantId}`);
                }
            }
        }
        catch (error) {
            console.error(`Error sending notification to merchant ${merchantId}:`, error);
        }
    }
}
exports.notificationService = new NotificationService();
