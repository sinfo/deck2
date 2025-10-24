<template>
  <div>
    <Button :size="size" :class="buttonClass" @click="isDialogOpen = true">
      <slot>Create Company</slot>
    </Button>

    <Teleport to="body">
      <AlertDialog v-model:open="isDialogOpen">
        <AlertDialogContent
          class="max-w-2xl max-h-[90vh] overflow-hidden flex flex-col"
        >
          <AlertDialogHeader class="flex-shrink-0">
            <AlertDialogTitle>Create New Company</AlertDialogTitle>
            <AlertDialogDescription>
              Fill out the information below to create a new company.
            </AlertDialogDescription>
          </AlertDialogHeader>

          <div class="flex-1 overflow-y-auto min-h-0">
            <CreateCompanyForm
              @cancel="handleCancel"
              @success="handleSuccess"
            />
          </div>
        </AlertDialogContent>
      </AlertDialog>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { Button } from "@/components/ui/button";
import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import CreateCompanyForm from "./CreateCompanyForm.vue";

interface Props {
  size?: "sm" | "default" | "lg" | "icon";
  buttonClass?: string;
}

withDefaults(defineProps<Props>(), {
  size: "sm",
  buttonClass: "",
});

const emit = defineEmits<{
  success: [companyId: string];
}>();

const isDialogOpen = ref(false);

const handleCancel = () => {
  isDialogOpen.value = false;
};

const handleSuccess = (companyId: string) => {
  isDialogOpen.value = false;
  emit("success", companyId);
};
</script>
