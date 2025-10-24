import { createApp } from "vue";
import { createPinia } from "pinia";
import { PiniaColada } from "@pinia/colada";

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
app.use(router);
app.mount("#app");
