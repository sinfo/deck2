<script setup lang="ts">
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useQuery } from '@pinia/colada';
import { getMyNotifications } from '@/api/notifications';
import { getSpeakerById } from '@/api/speakers';
import { getCompanyById } from '@/api/companies';
import { useDeleteNotificationMutation, useDeleteAllNotificationsMutation } from '@/mutations/notifications';
import type { EnrichedNotification } from '@/dto/notifications';
import { Bell, Trash } from 'lucide-vue-next';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import Badge from "../ui/badge/Badge.vue";
import Image from "../Image.vue";

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

const fetchEnrichedNotifications = async () => {
    const res: any = await getMyNotifications();
    const data = await Promise.all(
        (res.data || []).map(async (n: any) => {
            const enriched: any = { ...n };
            try {
                const speakerId = n.speaker || n.speakerId;
                const companyId = n.company || n.companyId;

                if (speakerId) {
                    const spRes: any = await getSpeakerById(speakerId);
                    const sp = spRes?.data || spRes;
                    if (sp) {
                        enriched.actor = {
                            type: 'speaker',
                            id: sp.id,
                            name: sp.name || (sp.contactObject && sp.contactObject.fullName) || null,
                            avatar: sp.imgs?.speaker || sp.imgs?.internal || sp.contactObject?.picture || null,
                        };
                        enriched.message = makeMessage(n.kind, enriched.actor);
                    }
                } else if (companyId) {
                    const coRes: any = await getCompanyById(companyId);
                    const co = coRes?.data || coRes;
                    if (co) {
                        enriched.actor = {
                            type: 'company',
                            id: co.id,
                            name: co.name || co.companyName || null,
                            avatar: co.imgs?.public || co.imgs?.internal || null,
                        };
                        enriched.message = makeMessage(n.kind, enriched.actor);
                    }
                }
            } catch (err) {
                // ignore enrichment errors
            }
            if (!enriched.message) enriched.message = makeMessage(n.kind, enriched.actor);
            return enriched;
        }),
    );
    return { ...res, data };
};

const { data: notifications } = useQuery({ key: ['notifications'], query: fetchEnrichedNotifications });

const notificationItems = computed(() => (notifications.value?.data as EnrichedNotification[]) || []);

const _deleteNotificationMutation = useDeleteNotificationMutation();
const _deleteAllNotificationsMutation = useDeleteAllNotificationsMutation();

const removeNotification = async (id: string) => {
    await _deleteNotificationMutation.mutate(id);
};

const removeAllNotifications = async () => {
    const ids = notificationItems.value.map((i: any) => i.id);
    if (!ids.length) return;
    await _deleteAllNotificationsMutation.mutate(ids);
};

const router = useRouter();
const navigateNotification = (n: EnrichedNotification) => {
    const actor = n.actor;
    if (actor?.type === 'speaker' && actor?.id) {
        router.push({ name: 'speaker', params: { speakerId: actor.id } });
        return;
    }
    if (actor?.type === 'company' && actor?.id) {
        router.push({ name: 'company', params: { companyId: actor.id } });
        return;
    }
};

const onNotificationClick = async (n: EnrichedNotification) => {
    if (!n || !n.id) return;
    try {
        await removeNotification(n.id);
    } catch (e) {
        // ignore
    }
    navigateNotification(n);
};

</script>

<template>
    <Popover>
        <PopoverTrigger>
            <button class="p-2 rounded hover:bg-gray-100 relative" :title="'Notifications'">
                <Bell class="h-5 w-5 text-gray-600" />
                <Badge v-if="notificationItems.length" variant="destructive" class="absolute -top-2 -right-1 text-xs">
                    {{ notificationItems.length }}
                </Badge>
            </button>
        </PopoverTrigger>

        <PopoverContent class="w-80 p-0">
            <div class="p-2 flex items-center justify-between border-b">
                <h4 class="font-semibold">Notifications</h4>
                <button v-if="notificationItems.length" class="text-sm text-blue-600" @click="removeAllNotifications()">
                    Read all
                </button>
            </div>

            <div class="max-h-60 overflow-auto">
                <div v-if="!notificationItems.length" class="p-4 text-sm text-gray-500">
                    No notifications
                </div>

                <ul>
                    <li v-for="n in notificationItems" :key="n.id"
                            class="flex items-center justify-between px-3 py-2 hover:bg-gray-50 cursor-pointer"
                            @click="onNotificationClick(n)">
                        <div class="flex items-center gap-3">
                            <Image v-if="n.actor && n.actor.avatar" :src="n.actor.avatar" alt="actor"
                                         class="h-8 w-8 rounded-full object-cover" />
                            <div class="text-sm">
                                <div class="font-medium">{{ n.message || n.kind }}</div>
                                <div class="text-xs text-gray-500">{{ n.actor?.name || n.date }}</div>
                            </div>
                        </div>
                        <div>
                            <button class="text-red-500 text-sm" @click.stop.prevent="removeNotification(n.id)">
                                <Trash :size="16" />
                            </button>
                        </div>
                    </li>
                </ul>
            </div>
        </PopoverContent>
    </Popover>
</template>