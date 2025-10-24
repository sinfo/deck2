<script setup lang="ts">
import type { ComboboxInputEmits, ComboboxInputProps } from "reka-ui";
import type { HTMLAttributes } from "vue";
import { reactiveOmit } from "@vueuse/core";
import { SearchIcon } from "lucide-vue-next";
import { ComboboxInput, useForwardPropsEmits } from "reka-ui";
import { cn } from "@/lib/utils";

defineOptions({
  inheritAttrs: false,
});

const props = defineProps<
  ComboboxInputProps & {
    class?: HTMLAttributes["class"];
  }
>();

const emits = defineEmits<ComboboxInputEmits>();

const delegatedProps = reactiveOmit(props, "class");

const forwarded = useForwardPropsEmits(delegatedProps, emits);
</script>

<template>
  <div
    data-slot="combobox-input-wrapper"
    :class="
      cn(
        'border-input focus-within:border-ring focus-within:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:bg-input/30 flex h-9 w-full items-center gap-2 rounded-md border bg-transparent px-3 py-2 text-sm shadow-xs transition-[color,box-shadow] outline-none focus-within:ring-[3px] has-[input:disabled]:cursor-not-allowed has-[input:disabled]:opacity-50',
        props.class,
      )
    "
  >
    <SearchIcon class="size-4 shrink-0 opacity-50" />
    <ComboboxInput
      data-slot="combobox-input"
      v-bind="{ ...forwarded, ...$attrs }"
      class="placeholder:text-muted-foreground flex-1 bg-transparent text-sm outline-none disabled:cursor-not-allowed"
    >
      <slot />
    </ComboboxInput>
  </div>
</template>
