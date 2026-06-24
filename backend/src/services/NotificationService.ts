import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging, MulticastMessage } from 'firebase-admin/messaging';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

class NotificationService {
  private isInitialized = false;

  constructor() {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      if (getApps().length === 0) {
        if (!process.env.FIREBASE_PRIVATE_KEY || !process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL) {
          console.warn('WARNING: Firebase credentials not found, running in MOCK mode. Push notifications will be simulated.');
          this.isInitialized = false;
          return;
        }

        initializeApp({
          credential: cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/^"|"$/g, '').replace(/\\n/g, '\n'),
          }),
        });
        
        this.isInitialized = true;
        console.log('Firebase Admin SDK initialized successfully.');
      } else {
        this.isInitialized = true;
      }
    } catch (error) {
      console.warn('WARNING: Failed to initialize Firebase Admin SDK. Running in MOCK mode.', error);
      this.isInitialized = false;
    }
  }

  public async sendToUser(userId: string, title: string, body: string, data?: { [key: string]: string }): Promise<void> {
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

      const message: MulticastMessage = {
        notification: {
          title,
          body,
        },
        data: data || {},
        tokens: tokens,
      };

      const response = await getMessaging().sendEachForMulticast(message);
      
      console.log(`Notification sent to user ${userId}. Success count: ${response.successCount}, Failure count: ${response.failureCount}`);

      // Cleanup invalid tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp: any, idx: number) => {
          if (!resp.success) {
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
    } catch (error) {
      console.error(`Error sending notification to user ${userId}:`, error);
    }
  }
}

export const notificationService = new NotificationService();
