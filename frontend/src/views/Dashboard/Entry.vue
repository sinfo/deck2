<template>
  <Navbar />

  <div class="container mx-auto p-4 pt-20">
    <router-view v-slot="{ Component, route }">
      <keep-alive :max="5">
        <component :is="Component" :key="route.path" />
      </keep-alive>
    </router-view>
  </div>
</template>

<script setup lang="ts">
import Navbar from "@/components/Navbar.vue";
</script>
