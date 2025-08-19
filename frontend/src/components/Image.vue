<template>
  <img :alt="alt" :src="src || defaultCompanyImg" @error="setAltImage" />
</template>

<script setup lang="ts">
import defaultCompanyImg from "@/assets/noImage.png";

defineProps<{
  src?: string;
  alt?: string;
}>();

const setAltImage = (event: Event) => {
  const target = event.target as HTMLImageElement;
  target.src = defaultCompanyImg;
};
</script>
