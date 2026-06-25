export interface ISmsProvider {
  sendOtp(phoneNumber: string, code: string): Promise<boolean>;
}
