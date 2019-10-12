import { Component, OnInit, ViewContainerRef } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

import { SpeakersService } from '../../../deck-api/speakers.service';
import { EventsService } from '../../../deck-api/events.service';
import { MembersService } from '../../../deck-api/members.service';
import { ThemeService } from '../../../theme.service';
import { ThreadsService } from '../../../deck-api/threads.service';
import { PostsService } from '../../../deck-api/posts.service';
import { EditFormService } from '../../../templates/edit-form/edit-form.service';
import { ContactsService } from '../../../deck-api/contacts.service';
import { MeService } from '../../../deck-api/me.service';

import { Event, EventComparator } from '../../../models/event';
import { GetParticipation, Speaker, SpeakerParticipation, SpeakerParticipationValidStatusSteps } from '../../../models/speaker';
import { Theme } from '../../../theme';
import { Member } from '../../../models/member';
import { Contact } from '../../../models/contact';
import { PopulatedThread, SortPopulatedThreads, Thread } from '../../../models/thread';
import { AppliedForm } from '../../../templates/edit-form/edit-form-communicator.service';

@Component({
    selector: 'app-speaker',
    templateUrl: './speaker.component.html',
    styleUrls: ['./speaker.component.css']
})
export class SpeakerComponent implements OnInit {

    private darkMode: boolean;

    speaker: Speaker;

    private participation: SpeakerParticipation;
    private contact: Contact;
    private member: Member;

    subscribed: boolean;

    private validSteps: SpeakerParticipationValidStatusSteps;

    private event: Event;
    private isCurrentEvent: boolean;
    private eventsOptions: {
        event: Event;
        participation: SpeakerParticipation
    }[];

    private threads: PopulatedThread[];
    private createThread = false;

    constructor(
        private route: ActivatedRoute,
        private themeService: ThemeService,
        private eventsService: EventsService,
        private speakersService: SpeakersService,
        private membersService: MembersService,
        private threadService: ThreadsService,
        private postsService: PostsService,
        private meService: MeService,
        private contactsService: ContactsService,
        private editFormService: EditFormService,
        public vcRef: ViewContainerRef
    ) {
    }

    ngOnInit() {
        const result = this.themeService.getThemeSubscription();
        this.darkMode = result.active.dark;
        result.subscription.subscribe((theme: Theme) => {
            this.darkMode = theme.dark;
        });
        this.refresh();
    }

    refreshThread(changedThread: PopulatedThread) {
        for (let i = 0; i < this.threads.length; i++) {
            if (this.threads[i].id !== changedThread.id) { continue; }

            this.threadService.getThread(this.threads[i].id).subscribe((updatedThread: Thread) => {

                const populatedThread = new PopulatedThread(updatedThread, this.postsService, this.membersService, () => {
                    if (populatedThread.comments.length === updatedThread.comments.length) {
                        this.threads[i] = populatedThread;
                        this.sortAndUpdateThreads(this.threads);
                    }
                });

            });
        }
    }

    refresh() {
        const speakerID = this.route.snapshot.params['id'];

        this.eventsService.getCurrentEvent().subscribe((event: Event) => {
            this.event = event;
            this.isCurrentEvent = true;

            this.speakersService.getSpeaker(speakerID).subscribe((speaker: Speaker) => {
                this.speaker = speaker;

                this.contactsService.getContact(speaker.contact).subscribe((contact: Contact) => {
                    this.contact = contact;
                });

                this.getEventsOptions(speaker);

                const participation = GetParticipation(this.speaker, event.id);

                if (participation === null) {
                    return;
                }

                this.updateParticipation(participation);
                this.updateThreads(participation);
            });
        });
    }

    selectEvent(event: Event, participation: SpeakerParticipation) {
        this.event = event;

        this.updateParticipation(participation);
        this.updateThreads(participation);

        this.eventsService.getCurrentEvent().subscribe((e: Event) => {
            this.isCurrentEvent = e.id === this.event.id;
        });
    }

    updateParticipation(participation: SpeakerParticipation) {
        this.participation = participation;

        this.meService.getMe().subscribe((me: Member) => {
            let subscribed = false;
            for (const subscriber of participation.subscribers) {
                if (subscriber === me.id) {
                    subscribed = true;
                    break;
                }
            }
            this.subscribed = subscribed;
        });

        this.membersService.getMember(participation.member).subscribe((member: Member) => {
            this.member = member;
        });
    }

    private getEventsOptions(speaker: Speaker) {
        this.eventsService.getEvents().subscribe((events: Event[]) => {

            const eventsOptions = [];
            events.sort(EventComparator);
            for (const event of events) {
                for (const participation of speaker.participations) {
                    if (participation.event === event.id) {
                        eventsOptions.push({ event: event, participation: participation });
                        break;
                    }
                }

            }

            this.eventsOptions = eventsOptions;
        });
    }

    private updateThreads(participation: SpeakerParticipation): void {
        this.threads = [];
        this.createThread = false;

        for (const threadID of participation.communications) {
            this.threadService.getThread(threadID).subscribe((thread: Thread) => {

                const populatedThread = new PopulatedThread(thread, this.postsService, this.membersService, () => {
                    if (populatedThread.comments.length === thread.comments.length) {
                        this.threads.push(populatedThread);
                        this.sortAndUpdateThreads(this.threads);
                    }
                });

            });
        }
    }

    private sortAndUpdateThreads(populatedThreads: PopulatedThread[]) {
        SortPopulatedThreads(populatedThreads);
        this.threads = populatedThreads;
    }

    openTemplate(postID: String) {
        const url = `${window.location.origin}/templates/events/${this.event.id}/speakers/${this.speaker.id}/posts/${postID}`;
        window.open(url, '_blank');
    }

    openEditSpeakerForm() {
        this.editFormService.showSpeakerEditForm(this.vcRef, this.speaker, (appliedForm: AppliedForm) => {
            this.updatedInfoCallback(appliedForm);
        });
    }

    updatedInfoCallback(infoType: AppliedForm) {
        const speakerID = this.route.snapshot.params['id'];

        switch (infoType) {
            case AppliedForm.EditSpeaker:
            case AppliedForm.EditSpeakerInternalImage:
            case AppliedForm.EditSpeakerParticipation:
                this.speakersService.getSpeaker(speakerID).subscribe((speaker: Speaker) => {
                    this.speaker = speaker;
                    const participation = GetParticipation(this.speaker, this.event.id);
                    if (participation === null) { return; }
                    this.updateParticipation(participation);
                });
                break;
            case AppliedForm.EditSpeakerContact:
                this.contactsService.getContact(this.speaker.contact).subscribe((contact: Contact) => {
                    this.contact = contact;
                });
                break;
            case AppliedForm.EditSpeakerParticipationStepStatus:
            case AppliedForm.EditSpeakerParticipationStatus:
                this.speakersService.getSpeaker(speakerID).subscribe((speaker: Speaker) => {
                    this.speaker = speaker;
                    this.getEventsOptions(speaker);
                    const participation = GetParticipation(this.speaker, this.event.id);
                    this.updateParticipation(participation);
                });
                break;
        }
    }

    toggleComment() {
        this.createThread = !this.createThread;
    }

    toggleSubscription() {
        if (this.subscribed === undefined) { return; }

        if (this.subscribed) {
            this.speakersService.unsubscribe(this.speaker.id).subscribe((speaker: Speaker) => {
                const participation = GetParticipation(speaker, this.event.id);

                if (participation === null) {
                    return;
                }

                this.updateParticipation(participation);
            });
        } else {
            this.speakersService.subscribe(this.speaker.id).subscribe((speaker: Speaker) => {
                const participation = GetParticipation(speaker, this.event.id);

                if (participation === null) {
                    return;
                }

                this.updateParticipation(participation);
            });
        }
    }

}
