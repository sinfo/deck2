import { useAuthStore } from "@/stores/auth";
import axios from "axios";

export const instance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
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
