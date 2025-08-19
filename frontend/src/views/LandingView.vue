<template>
  <div class="grid min-h-svh lg:grid-cols-[30%_70%]">
    <div class="flex flex-col gap-4 p-6 md:p-10">
      <div class="flex justify-center gap-2 md:justify-start">
        <a href="#" class="flex items-center gap-2 font-medium">
          <div class="flex h-6 w-6 items-center justify-center rounded-md bg">
            <img alt="Logo" src="@/assets/logos/Logo_Light.png" />
          </div>
          SINFO
        </a>
      </div>
      <div class="flex flex-1 items-center justify-center">
        <div class="w-full max-w-xs">
          <LoginForm />
        </div>
      </div>
      <div class="flex justify-center text-sm text-muted-foreground">
        Visit
        <a
          href="https://sinfo.org"
          target="_blank"
          class="ml-1 text-primary hover:text-primary/80 underline transition-colors"
          >sinfo.org</a
        >
      </div>
    </div>
    <div class="relative hidden bg-muted lg:block overflow-hidden">
      <div
        v-for="(image, index) in images"
        :key="image"
        class="absolute inset-0 transition-opacity duration-1000 ease-in-out"
        :class="{
          'opacity-100': index === currentImageIndex,
          'opacity-0': index !== currentImageIndex,
        }"
      >
        <img
          :alt="`Slideshow image ${index + 1}`"
          class="h-full w-full object-cover dark:brightness-[0.2] dark:grayscale"
          :src="image"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, onUnmounted } from "vue";
import LoginForm from "@/components/LoginForm.vue";

// Import images explicitly for Vite bundling
import Chillin from "@/assets/landing/Chillin.jpg";
import Hacky from "@/assets/landing/Hacky.jpg";
import People from "@/assets/landing/People.jpg";
import Team from "@/assets/landing/Team.jpg";

const images = [Chillin, Hacky, People, Team].sort(() => Math.random() - 0.5);

const currentImageIndex = ref(0);
let intervalId: number | null = null;

const nextImage = () => {
  currentImageIndex.value = (currentImageIndex.value + 1) % images.length;
};

onMounted(() => {
  // Start the slideshow with a 4-second interval
  intervalId = window.setInterval(nextImage, 4000);
});

onUnmounted(() => {
  if (intervalId) {
    clearInterval(intervalId);
  }
});
</script>
