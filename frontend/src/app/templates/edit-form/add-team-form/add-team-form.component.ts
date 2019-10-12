import { Component } from '@angular/core';

import { AddTeamForm } from '../../../models/team';

import { EditFormCommunicatorService, AppliedForm } from '../edit-form-communicator.service';
import { TeamsService } from '../../../deck-api/teams.service';

@Component({
    selector: 'app-add-team-form',
    templateUrl: './add-team-form.component.html',
    styleUrls: ['./add-team-form.component.css']
})
export class AddTeamFormComponent {

    form: AddTeamForm;

    constructor(
        private editFormCommunicatorService: EditFormCommunicatorService,
        private teamsService: TeamsService,
    ) {
        this.form = new AddTeamForm();
    }

    submitNewTeam() {
        if (!this.form.valid()) { return; }

        this.teamsService.createTeam(this.form).subscribe(() => {
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.AddTeam);
        });
    }

}
