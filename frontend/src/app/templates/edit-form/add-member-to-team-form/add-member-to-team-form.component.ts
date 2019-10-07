import { Component, OnInit } from '@angular/core';
import { FormBuilder } from '@angular/forms';

import { PopulatedTeam, AddMemberToTeamForm, Team } from '../../../models/team';
import { Member } from '../../../models/member';

import { EditFormCommunicatorService, AppliedForm } from '../edit-form-communicator.service';
import { TeamsService } from '../../../deck-api/teams.service';

@Component({
    selector: 'app-add-member-to-team-form',
    templateUrl: './add-member-to-team-form.component.html',
    styleUrls: ['./add-member-to-team-form.component.css']
})
export class AddMemberToTeamFormComponent implements OnInit {

    member: Member;
    team: PopulatedTeam;

    form: AddMemberToTeamForm;

    constructor(
        private formBuilder: FormBuilder,
        private editFormCommunicatorService: EditFormCommunicatorService,
        private teamsService: TeamsService
    ) {
        this.team = this.editFormCommunicatorService.data;
    }

    ngOnInit() {
        this.form = new AddMemberToTeamForm();
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
