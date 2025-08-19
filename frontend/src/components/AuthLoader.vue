<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-background"
  >
    <div class="flex flex-col items-center gap-4">
      <div
        class="flex h-12 w-12 items-center justify-center rounded-md bg-primary/10"
      >
        <img alt="Logo" src="@/assets/logos/Logo_Light.png" class="h-8 w-8" />
      </div>
      <div class="flex flex-col items-center gap-2">
        <div class="h-2 w-32 animate-pulse rounded-full bg-primary/20"></div>
        <p class="text-sm text-muted-foreground">Checking authentication...</p>
      </div>
    </div>
  </div>
</template>
