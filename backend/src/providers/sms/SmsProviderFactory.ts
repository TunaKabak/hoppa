import { ISmsProvider } from "./ISmsProvider";
import { MockSmsProvider } from "./MockSmsProvider";
import { TwilioSmsProvider } from "./TwilioSmsProvider";

export class SmsProviderFactory {
  public static getProvider(): ISmsProvider {
    const mode = process.env.SMS_PROVIDER_MODE || "MOCK";

    if (mode === "TWILIO") {
      return new TwilioSmsProvider();
    }

    return new MockSmsProvider();
  }
}
