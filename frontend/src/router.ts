import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "./stores/auth";

const LandingView = () => import("./views/LandingView.vue");
const DashboardEntry = () => import("./views/Dashboard/Entry.vue");

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: "/", name: "landing", component: LandingView },
    {
      path: "/app",
      component: DashboardEntry,
      meta: { requiresAuth: true },
      children: [
        {
          path: "",
          name: "dashboard",
          component: () => import("./views/Dashboard/ResponsibilitiesView.vue"),
        },
        {
          path: "companies",
          name: "companies",
          component: () =>
            import("./views/Dashboard/Companies/CompaniesView.vue"),
        },
        {
          path: "companies/:companyId",
          name: "company",
          component: () =>
            import("./views/Dashboard/Companies/CompanyView.vue"),
        },
        {
          path: "speakers",
          name: "speakers",
          component: () =>
            import("./views/Dashboard/Speakers/SpeakersView.vue"),
        },
        {
          path: "speakers/:speakerId",
          name: "speaker",
          component: () => import("./views/Dashboard/Speakers/SpeakerView.vue"),
        },
        {
          path: "settings",
          name: "settings",
          component: () => import("./views/Dashboard/SettingsView.vue"),
        },
        {
          path: "leaderboard",
          name: "leaderboard",
          component: () =>
            import("./views/Dashboard/Leaderboard/LeaderboardView.vue"),
        },
      ],
    },
  ],
});

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore();

  // Wait for auth initialization to complete
  if (authStore.isInitializing) {
    await authStore.initialize();
  }

  // If user is authenticated and trying to access landing page, redirect to dashboard
  if (to.name === "landing" && authStore.isAuthenticated) {
    next({ name: "dashboard" });
    return;
  }

  // If route requires auth and user is not authenticated, redirect to landing
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next({ name: "landing", query: { to: to.fullPath || from.fullPath } });
    return;
  }

  next();
});

export default router;
