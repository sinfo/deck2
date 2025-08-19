import { env } from "@/env";
import { useAuthStore } from "@/stores/auth";
import axios from "axios";

export const instance = axios.create({
  baseURL: env.API_URL,
});

instance.interceptors.request.use(
  (config) => {
    const auth = useAuthStore();

    if (auth.token) {
      config.headers.Authorization = auth.token;
    }

    return config;
  },
  (error) => {
    return Promise.reject(error);
  },
);
