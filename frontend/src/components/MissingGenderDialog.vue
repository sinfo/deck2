<template>
  <AlertDialog v-model:open="open">
    <AlertDialogContent>
      <AlertDialogHeader>
        <AlertDialogTitle>Your gender is not set</AlertDialogTitle>
        <AlertDialogDescription>
          This template uses gender-specific language to refer to you, so you
          need to set your gender in your profile before using it.
        </AlertDialogDescription>
      </AlertDialogHeader>
      <p class="rounded-md bg-muted px-3 py-2 text-sm font-medium">
        Go to Settings → Contact Information → Edit → Gender → Update Contact
      </p>
      <AlertDialogFooter>
        <AlertDialogCancel>Close</AlertDialogCancel>
        <AlertDialogAction @click="goToSettings">
          Go to Settings
        </AlertDialogAction>
      </AlertDialogFooter>
    </AlertDialogContent>
  </AlertDialog>
</template>

<script setup lang="ts">
import { useRouter } from "vue-router";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

const open = defineModel<boolean>("open", { default: false });

const router = useRouter();

const goToSettings = () => {
  open.value = false;
  router.push({ name: "settings" });
};
</script>
