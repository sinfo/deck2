import { Component, Input, OnInit, ViewContainerRef } from '@angular/core';

import { FilterService } from './filter.service';
import { EditFormService } from '../../../templates/edit-form/edit-form.service';

import { Filters, FilterField } from './filter';
import { AppliedForm } from '../../../templates/edit-form/edit-form-communicator.service';

@Component({
    selector: 'app-filter',
    templateUrl: './filter.component.html',
    styleUrls: ['./filter.component.css']
})
export class FilterComponent implements OnInit {

    @Input() filters: Filters;

    currentEvent: Event;

    constructor(
        private filterService: FilterService,
        private editFormService: EditFormService,
        public vcRef: ViewContainerRef
    ) { }

    ngOnInit() { }

    eventsOptions() {
        if (this.filters.speaker) {
            return this.filters.speaker.getOptions(FilterField.Event);
        }

        if (this.filters.member) {
            return this.filters.member.getOptions(FilterField.Event);
        }

        if (this.filters.team) {
            return this.filters.team.getOptions(FilterField.Event);
        }
    }

    statusOptions() {
        return this.filters.speaker.getOptions(FilterField.Status);
    }

    changeEvent(event: string) {
        // if it's selected the current event, then unset the filter
        if (event.length === 0 || event === `${this.filters.speaker.getOptions(FilterField.Event)[0]}`) {
            this.filters.speaker.setValue(FilterField.Event, null, !this.filters.speaker.isSet(FilterField.Name));
            this.filters.member.setValue(FilterField.Event, null);
        } else {
            this.filters.speaker.setValue(FilterField.Event, +event);
            this.filters.member.setValue(FilterField.Event, +event);
        }

        this.filterService.changeFilters(this.filters);
    }

    changeStatus(status: string) {
        if (status.length === 0) {
            this.filters.speaker.setValue(FilterField.Status, null);
        } else {
            this.filters.speaker.setValue(FilterField.Status, status);
        }

        this.filterService.changeFilters(this.filters);
    }

    changeMember(member: string) {
        if (member.length === 0) {
            this.filters.member.setValue(FilterField.Name, null);
        } else {
            this.filters.member.setValue(FilterField.Name, member);
        }

        this.filterService.changeFilters(this.filters);
    }

    changeSpeaker(speaker: string) {
        if (speaker.length === 0) {
            this.filters.speaker.setValue(FilterField.Name, null);

            if (!this.filters.speaker.isSet(FilterField.Event)) {
                this.filters.speaker.setValue(FilterField.Event, null, true);
            }
        } else {
            this.filters.speaker.setValue(FilterField.Name, speaker);

            if (this.filters.speaker.isDefaultValue(FilterField.Event)) {
                this.filters.speaker.setValue(FilterField.Event, null, false);
            }
        }

        this.filterService.changeFilters(this.filters);
    }

    changeTeamMember(member: string) {
        if (member.length === 0) {
            this.filters.team.setValue(FilterField.MemberName, null);
        } else {
            this.filters.team.setValue(FilterField.MemberName, member);
        }

        this.filterService.changeFilters(this.filters);
    }

    changeTeamEvent(event: string) {
        // if it's selected the current event, then unset the filter
        if (event.length === 0 || event === `${this.filters.team.getOptions(FilterField.Event)[0]}`) {
            this.filters.team.setValue(FilterField.Event, null, true);
        } else {
            this.filters.team.setValue(FilterField.Event, +event);
        }

        this.filterService.changeFilters(this.filters);
    }

    changeTeamName(team: string) {
        if (team.length === 0) {
            this.filters.team.setValue(FilterField.Name, null);
        } else {
            this.filters.team.setValue(FilterField.Name, team);
        }

        this.filterService.changeFilters(this.filters);
    }

    addSpeaker() {
        this.editFormService.showAddSpeakerForm(this.vcRef, (appliedForm: AppliedForm) => {
            this.filterService.changeFilters(this.filters);
        });
    }

}
