<template>
  <div class="p-4">
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div>
        <ItemsAdmin />
      </div>
      <div>
        <CategoriesAdmin />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import ItemsAdmin from "./ItemsAdmin.vue";
import CategoriesAdmin from "./CategoriesAdmin.vue";
</script>
