import type { AuthRequest, AuthResponse } from "@/dto/auth";
import { instance } from ".";

export const generateJwt = (authRequest: AuthRequest) =>
  instance.post<AuthResponse>("/auth/checkin", authRequest);
