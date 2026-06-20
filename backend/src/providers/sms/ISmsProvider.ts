export interface ISmsProvider {
  sendSms(phoneNumber: string, message: string): Promise<boolean>;
}
