import { Component, OnInit, ViewChild } from '@angular/core';
import { FormBuilder } from '@angular/forms';

import { NgbTypeaheadSelectItemEvent } from '@ng-bootstrap/ng-bootstrap';
import { Observable, of } from 'rxjs';
import { debounceTime, distinctUntilChanged, tap, switchMap, catchError } from 'rxjs/operators';

import { PopulatedTeam, AddMemberToTeamForm, Team } from '../../../models/team';
import { Member } from '../../../models/member';
import { RoleType } from '../../../models/role';
import { FilterMember, FilterField } from '../../../home/content/filter/filter';

import { EditFormCommunicatorService, AppliedForm } from '../edit-form-communicator.service';
import { TeamsService } from '../../../deck-api/teams.service';
import { MembersService } from '../../../deck-api/members.service';
import { EventsService } from '../../../deck-api/events.service';

@Component({
    selector: 'app-add-member-to-team-form',
    templateUrl: './add-member-to-team-form.component.html',
    styleUrls: ['./add-member-to-team-form.component.css']
})
export class AddMemberToTeamFormComponent implements OnInit {

    member: Member;
    team: PopulatedTeam;

    model: any;
    searching = false;
    searchFailed = false;

    form: AddMemberToTeamForm;
    memberFilter: FilterMember;

    constructor(
        private formBuilder: FormBuilder,
        private editFormCommunicatorService: EditFormCommunicatorService,
        private teamsService: TeamsService,
        private membersService: MembersService,
        private eventsService: EventsService,
    ) {
        this.team = this.editFormCommunicatorService.data;
    }

    ngOnInit() {
        const _ = new FilterMember(this.eventsService, (f: FilterMember) => {
            this.memberFilter = f;
            this.form = new AddMemberToTeamForm();
        });
    }

    search = (text$: Observable<string>) => {
        return text$.pipe(
            debounceTime(300),
            distinctUntilChanged(),
            tap(() => this.searching = true),
            switchMap(term => {
                this.memberFilter.setValue(FilterField.Name, term);
                return this.membersService.getMembers(this.memberFilter).pipe(
                    tap(() => this.searchFailed = false),
                    catchError(() => {
                        this.searchFailed = true;
                        return of([]);
                    }));
            }
            ),
            tap(() => this.searching = false)
        );
    }

    formatter = (x: { name: string }) => x.name;

    selectMember(payload: NgbTypeaheadSelectItemEvent) {
        const member: Member = payload.item;
        this.form.form.controls['member'].setValue(member.id);
    }

    selectRole(role: RoleType) {
        this.form.form.controls['role'].setValue(role);
    }

    submit() {
        if (!this.form.valid()) {
            return;
        }

        this.teamsService.addMemberToTeam(`${this.team.id}`, this.form).subscribe((team: Team) => {
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.AddMemberToTeam);
        });
    }

}
