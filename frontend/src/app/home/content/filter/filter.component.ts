import { Component, Input, OnInit, ViewContainerRef } from '@angular/core';

import { FilterService } from './filter.service';
import { EditFormService } from '../../../templates/edit-form/edit-form.service';
import { MeService } from '../../../deck-api/me.service';

import { Filter, Filters, FilterField, FilterType } from './filter';
import { Role, CoordinatorAccessLevel } from '../../../models/role';

@Component({
    selector: 'app-filter',
    templateUrl: './filter.component.html',
    styleUrls: ['./filter.component.css']
})
export class FilterComponent implements OnInit {

    @Input() filters: Filters;

    currentEvent: Event;
    coordinatorAccessLevel: boolean;

    constructor(
        private filterService: FilterService,
        private editFormService: EditFormService,
        private meService: MeService,
        public vcRef: ViewContainerRef
    ) { }

    ngOnInit() {
        this.meService.getMyRole().subscribe((role: Role) => {
            this.coordinatorAccessLevel = CoordinatorAccessLevel(role);
        });
    }

    eventsOptions(filter: Filter) {
        return filter.getOptions(FilterField.Event);
    }

    statusOptions(filter: Filter) {
        return filter.getOptions(FilterField.Status);
    }

    changeEvent(filter: Filter, event: string) {
        // if it's selected the current event, then unset the filter
        if (event.length === 0 || event === `${filter.getOptions(FilterField.Event)[0]}`) {

            if (filter.isType(FilterType.Speaker) || filter.isType(FilterType.Company)) {
                filter.setValue(FilterField.Event, null, !filter.isSet(FilterField.Name));
                this.filters.member.setValue(FilterField.Event, null);
            } else {
                filter.setValue(FilterField.Event, null);
            }

        } else {
            filter.setValue(FilterField.Event, +event);

            if (filter.isType(FilterType.Speaker) || filter.isType(FilterType.Company)) {
                this.filters.member.setValue(FilterField.Event, +event);
            }
        }

        this.filterService.changeFilters(this.filters);
    }

    changeStatus(filter: Filter, status: string) {
        if (status.length === 0) {
            filter.setValue(FilterField.Status, null);
        } else {
            filter.setValue(FilterField.Status, status);
        }

        this.filterService.changeFilters(this.filters);
    }

    changeName(filter: Filter, name: string) {
        if (name.length === 0) {

            if (!filter.isSet(FilterField.Event)) {
                filter.setValue(FilterField.Event, null, true);
            } else {
                filter.setValue(FilterField.Name, null);
            }

        } else {
            filter.setValue(FilterField.Name, name);

            if (filter.isDefaultValue(FilterField.Event)) {
                filter.setValue(FilterField.Event, null, false);
            }
        }

        this.filterService.changeFilters(this.filters);
    }

    changeMemberName(filter: Filter, member: string) {
        if (member.length === 0) {
            filter.setValue(FilterField.MemberName, null);
        } else {
            filter.setValue(FilterField.MemberName, member);
        }

        this.filterService.changeFilters(this.filters);
    }

    changeType(filter: Filter, type: string) {
        if (type.length === 0) {
            filter.setValue(FilterField.Type, null);
        } else {
            filter.setValue(FilterField.Type, type);
        }

        this.filterService.changeFilters(this.filters);
    }

    addSpeaker() {
        this.editFormService.showAddSpeakerForm(this.vcRef, () => {
            this.filterService.changeFilters(this.filters);
        });
    }

    addCompany() {
        this.editFormService.showAddCompanyForm(this.vcRef, () => {
            this.filterService.changeFilters(this.filters);
        });
    }

    addItem() {
        this.editFormService.showAddItemForm(this.vcRef, () => {
            this.filterService.changeFilters(this.filters);
        });
    }

    addTeam() {
        this.editFormService.showAddTeamForm(this.vcRef, () => {
            this.filterService.changeFilters(this.filters);
            this.editFormService.closeForm();
        });
    }

}
