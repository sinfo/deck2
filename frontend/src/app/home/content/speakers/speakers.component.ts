import { Component, OnInit, OnDestroy } from '@angular/core';

import { SpeakersService } from '../../../deck-api/speakers.service';
import { EventsService } from '../../../deck-api/events.service';
import { MembersService } from '../../../deck-api/members.service';
import { FilterService } from '../filter/filter.service';

import { Speaker, SpeakerParticipation } from '../../../models/speaker';
import { Member } from '../../../models/member';
import { FilterField, FilterType, Filters } from '../filter/filter';
import { Subscription } from 'rxjs';

@Component({
    selector: 'app-speakers',
    templateUrl: './speakers.component.html',
    styleUrls: ['./speakers.component.css']
})
export class SpeakersComponent implements OnInit, OnDestroy {

    filterSubscription: Subscription;
    filters: Filters;

    private speakers: Speaker[];
    private members: Member[];

    speakersByMember: {
        member: Member,
        speakers: {
            speaker: Speaker,
            participation: SpeakerParticipation
        }[]
    }[];

    constructor(
        private eventsService: EventsService,
        private speakersService: SpeakersService,
        private membersService: MembersService,
        private filterService: FilterService,
    ) {
        this.filterSubscription = this.filterService.getFiltersSubscription().subscribe((filters: Filters) => {
            this.filters = filters;
            this.fetchAndFilterSpeakers();
        });
    }

    ngOnInit() {
        this.filters = new Filters(this.eventsService);
        this.filters.initFilters(FilterType.Speaker, [FilterType.Member], () => {
            this.fetchAndFilterSpeakers();
        });
    }

    ngOnDestroy() {
        this.filterSubscription.unsubscribe();
    }

    fetchAndFilterSpeakers() {
        this.speakersByMember = [];

        this.membersService.getMembers(this.filters.member).subscribe((members: Member[]) => {
            this.members = members;

            this.speakersService.getSpeakers(this.filters.speaker).subscribe((speakers: Speaker[]) => {
                this.speakers = speakers;
                this.speakersByMember = [];

                this.filterSpeakers();
            });
        });
    }

    private filterSpeakers() {
        const eventID = this.filters.speaker.getValue(FilterField.Event);

        for (const speaker of this.speakers) {
            const filteredParticipations = speaker.participations.filter((p: SpeakerParticipation) => {
                if (!this.filters.speaker.isSet(FilterField.Name) && p.event !== eventID) { return false; }
                if (this.filters.speaker.isSet(FilterField.Status)) {
                    return this.filters.speaker.getValue(FilterField.Status) === p.status;
                }
                return true;
            });

            const participation = filteredParticipations.length ? filteredParticipations[filteredParticipations.length - 1] : null;
            if (participation === null && this.filters.speaker.isSet(FilterField.Status)) { continue; }

            const filteredMembers = participation ? this.members.filter((m: Member) => {
                return m.id === participation.member;
            }) : [];

            const member = filteredMembers.length ? filteredMembers[0] : null;

            if (this.filters.member.isSet(FilterField.Name) && member === null) { continue; }
            this.addSpeakerToMember(speaker, participation, member);
        }

        this.speakersByMember.sort((a, b) => {
            if (a.member === null) { return -1; }
            if (b.member === null) { return 1; }
            return (a.member.name > b.member.name) ? 1 : ((b.member.name > a.member.name) ? -1 : 0)
        });
    }

    private addSpeakerToMember(speaker: Speaker, participation: SpeakerParticipation, member: Member) {

        let found = false;
        for (const savedSpeaker of this.speakersByMember) {
            if (savedSpeaker.member === member) {
                savedSpeaker.speakers.push({
                    speaker: speaker,
                    participation: participation
                });
                found = true;
                break;
            }
        }

        if (!found) {
            this.speakersByMember.push({
                member: member,
                speakers: [{
                    speaker: speaker,
                    participation: participation
                }]
            });
        }
    }

}
