import { defineMutation, useMutation, useQueryCache } from "@pinia/colada";
import {
  deleteAllMyNotifications,
  deleteMyNotification,
} from "@/api/notifications";
import type { Notification } from "@/dto/notifications";

export const useDeleteNotificationMutation = defineMutation(() => {
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: (id: string) => deleteMyNotification(id),
    onMutate: (id: string) => {
      // optimistic: remove the notification from the "notifications" query
      const prev = queryCache.getQueryData<{ data: Notification[] }>([
        "notifications",
      ]) || {
        data: [],
      };
      const newData = (prev.data || []).filter(
        (n: Notification) => n.id !== id,
      );
      queryCache.setQueryData(["notifications"], { ...prev, data: newData });
      // cancel ongoing queries
      queryCache.cancelQueries({ key: ["notifications"] });
      return { prev };
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (_err, _id, context: any) => {
      // rollback
      if (context?.prev) {
        queryCache.setQueryData(["notifications"], context.prev);
      }
    },
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["notifications"] });
    },
  });

  return { mutate, ...mutation };
});

export const useDeleteAllNotificationsMutation = defineMutation(() => {
  const queryCache = useQueryCache();

  const { mutate, ...mutation } = useMutation({
    mutation: () => deleteAllMyNotifications(),
    onMutate: () => {
      const prev = queryCache.getQueryData(["notifications"]) || { data: [] };
      // optimistic: clear notifications
      queryCache.setQueryData(["notifications"], { ...prev, data: [] });
      queryCache.cancelQueries({ key: ["notifications"] });
      return { prev };
    },
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onError: (_err, _ids, context: any) => {
      if (context?.prev) {
        queryCache.setQueryData(["notifications"], context.prev);
      }
    },
    onSettled: () => {
      queryCache.invalidateQueries({ key: ["notifications"] });
    },
  });

  return { mutate, ...mutation };
});
