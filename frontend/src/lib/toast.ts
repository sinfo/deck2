import { reactive } from "vue";

type ToastRecord = {
  id: number;
  title?: string;
  description?: string;
  type?: "info" | "success" | "error" | "warning";
};

const state = reactive<{ toasts: ToastRecord[] }>({ toasts: [] });

let nextId = 1;

export function useToast() {
  const push = (t: Omit<ToastRecord, "id"> & { duration?: number }) => {
    const id = nextId++;
    const record: ToastRecord = {
      id,
      title: t.title,
      description: t.description,
      type: t.type || "info",
    };
    state.toasts.push(record);
    const duration = t.duration ?? 4000;
    setTimeout(() => {
      const idx = state.toasts.findIndex((x) => x.id === id);
      if (idx !== -1) state.toasts.splice(idx, 1);
    }, duration);
    return id;
  };

  return {
    toasts: state.toasts,
    toast: {
      info: (opts: Omit<ToastRecord, "id"> & { duration?: number }) =>
        push({ ...opts, type: "info" }),
      success: (opts: Omit<ToastRecord, "id"> & { duration?: number }) =>
        push({ ...opts, type: "success" }),
      error: (opts: Omit<ToastRecord, "id"> & { duration?: number }) =>
        push({ ...opts, type: "error" }),
      warning: (opts: Omit<ToastRecord, "id"> & { duration?: number }) =>
        push({ ...opts, type: "warning" }),
    },
    dismiss: (id: number) => {
      const idx = state.toasts.findIndex((x) => x.id === id);
      if (idx !== -1) state.toasts.splice(idx, 1);
    },
  };
}

export default useToast;
