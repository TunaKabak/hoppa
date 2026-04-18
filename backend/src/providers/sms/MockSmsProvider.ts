import { ISmsProvider } from "./ISmsProvider";

export class MockSmsProvider implements ISmsProvider {
  async sendSms(phoneNumber: string, message: string): Promise<boolean> {
    console.log(`[MOCK SMS] To: ${phoneNumber} | Message: ${message}`);
    return true;
  }
}
