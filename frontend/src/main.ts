import { createApp } from "vue";
import { createPinia } from "pinia";
import { PiniaColada } from "@pinia/colada";
import vue3GoogleLogin from "vue3-google-login";

import "./index.css";
import App from "./App.vue";
import router from "./router";

const app = createApp(App);
const pinia = createPinia();
app.use(pinia);
app.use(PiniaColada, {
  queryOptions: {
    gcTime: 300_000, // 5 minutes
  },
});
app.use(vue3GoogleLogin, {
  clientId: import.meta.env.VITE_GOOGLE_CLIENT_ID,
});
app.use(router);
app.mount("#app");
