import { z } from "zod";

export const requestOtpSchema = z.object({
  phoneNumber: z.string().min(10, "Telefon numarası en az 10 karakter olmalıdır.")
});

export const verifyOtpSchema = z.object({
  phoneNumber: z.string().min(10, "Telefon numarası en az 10 karakter olmalıdır."),
  code: z.string().length(6, "Doğrulama kodu 6 haneli olmalıdır.")
});

export const applyCourierSchema = z.object({
  name: z.string().min(2, "İsim en az 2 karakter olmalıdır."),
  phoneNumber: z.string().min(10, "Telefon numarası en az 10 karakter olmalıdır."),
  vehiclePlate: z.string().optional().nullable(),
  vehicleType: z.enum(["MOTORCYCLE", "CAR", "BICYCLE", "FOOT"]).optional(),
  workingHours: z.any().optional().nullable(),
  maxServiceDistanceKm: z.number().optional().nullable()
});
