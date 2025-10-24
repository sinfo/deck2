import { defineStore } from 'pinia';
import { ref } from 'vue';
import { getMyNotifications, deleteMyNotification } from '@/api/notifications';
import type { Notification } from '@/dto/notifications';
import { getSpeakerById } from '@/api/speakers';
import { getCompanyById } from '@/api/companies';

export const useNotificationsStore = defineStore('notifications', () => {
  const items = ref<Notification[]>([]);
  const loading = ref(false);

  const fetch = async () => {
    loading.value = true;
    try {
    const res = await getMyNotifications();

    // enrich notifications with speaker or company details (name + avatar/logo)
    // backend uses `speaker` and `company` fields (object ids)
    res.data = await Promise.all(
      res.data.map(async (n: any) => {
        const enriched = { ...n };
        try {
          // if backend returns speaker/company as an id string
          const speakerId = n.speaker || n.speakerId;
          const companyId = n.company || n.companyId;

          if (speakerId) {
            const spRes: any = await getSpeakerById(speakerId);
            const sp = spRes?.data || spRes;
            if (sp) {
              enriched.actor = {
                type: "speaker",
                id: sp.id,
                name: sp.name || (sp.contactObject && sp.contactObject.fullName) || null,
                avatar: sp.imgs?.speaker || sp.imgs?.internal || sp.contactObject?.picture || null,
              };
              // message based on kind and actor
              enriched.message = makeMessage(n.kind, enriched.actor);
            }
          } else if (companyId) {
            const coRes: any = await getCompanyById(companyId);
            const co = coRes?.data || coRes;
            if (co) {
              enriched.actor = {
                type: "company",
                id: co.id,
                name: co.name || co.companyName || null,
                avatar: co.imgs?.public || co.imgs?.internal || null,
              };
              enriched.message = makeMessage(n.kind, enriched.actor);
            }
          }
        } catch (err) {
          // swallow enrichment errors; keep original notification
        }
        // ensure there's always a short message describing the notification
        if (!enriched.message) {
          enriched.message = makeMessage(n.kind, enriched.actor);
        }
        return enriched;
      }),
    );
      items.value = res.data;
    } finally {
      loading.value = false;
    }
  };

  const remove = async (id: string) => {
    await deleteMyNotification(id);
    items.value = items.value.filter((i) => i.id !== id);
  };

  const removeAll = async () => {
    const ids = items.value.map((i) => i.id);
    // delete in parallel
    await Promise.all(ids.map((id) => deleteMyNotification(id).catch(() => {})));
    items.value = [];
  };

  // build a small human-readable message for the notification
  const makeMessage = (kind: string, actor: any) => {
    const actorName = actor?.name || null;
    switch (kind) {
      case 'UPDATED_PARTICIPATION':
        return 'Participation updated';
      case 'UPDATED_PARTICIPATION_STATUS':
        return 'Participation status changed';
      case 'CREATED_PARTICIPATION':
        return 'New participation';
      case 'DELETED_PARTICIPATION':
        return 'Participation removed';
      case 'UPLOADED_MEETING_MINUTE':
        return 'Meeting minute uploaded';
      case 'DELETED_MEETING_MINUTE':
        return 'Meeting minute deleted';
      case 'UPDATED_PRIVATE_IMAGE':
        return 'Private image updated';
      case 'UPDATED':
        return 'Updated details';
      case 'CREATED':
        return 'Created';
      case 'DELETED':
        return actorName ? `${actorName} deleted` : 'Deleted';
      case 'TAGGED':
        return 'You were tagged in a post';
      default:
        return actorName ? `${kind} - ${actorName}` : kind;
    }
  };

  return { items, loading, fetch, remove, removeAll };
});
