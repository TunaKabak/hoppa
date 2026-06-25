import { ISmsProvider } from "./ISmsProvider";

export class MockSmsProvider implements ISmsProvider {
  public async sendOtp(phoneNumber: string, code: string): Promise<boolean> {
    console.log(`\n--- [MOCK SMS GATEWAY] ---`);
    console.log(`Alıcı: ${phoneNumber}`);
    console.log(`Mesaj: Hoppa doğrulama kodunuz: ${code}`);
    console.log(`-------------------------\n`);
    return true;
  }
}
