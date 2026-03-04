<template>
  <Teleport to="body">
    <div
      v-if="showConfetti"
      class="fixed left-1/2 top-1/3 pointer-events-none z-[9999] -translate-x-1/2 -translate-y-1/2"
    >
      <ConfettiExplosion
        :particle-count="500"
        :particle-size="10"
        :duration="2500"
        :force="0.5"
        :stage-height="height"
        :stage-width="width"
      />
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import ConfettiExplosion from "vue-confetti-explosion";
import { useConfetti } from "@/composables/useConfetti";
import { useWindowSize } from "@vueuse/core";

const { showConfetti } = useConfetti();
const { width, height } = useWindowSize();
</script>
