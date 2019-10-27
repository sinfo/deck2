import { Component } from '@angular/core';
import { FormBuilder } from '@angular/forms';

import {
    EditTeamMemberRoleForm, PopulatedTeamMember, Team,
} from '../../models/team';
import { RoleType } from '../../models/role';

import { TeamsService } from '../../deck-api/teams.service';

import { EditFormCommunicatorService, AppliedForm } from '../edit-form/edit-form-communicator.service';

@Component({
  selector: 'app-edit-team-member',
  templateUrl: './edit-team-member.component.html',
  styleUrls: ['./edit-team-member.component.css']
})
export class EditTeamMemberComponent {

  form: EditTeamMemberRoleForm;

  team: Team;
  teamMember: PopulatedTeamMember;

  constructor(
    private editFormCommunicatorService: EditFormCommunicatorService,
    private teamsService: TeamsService,
  ) { 
    this.teamMember = this.editFormCommunicatorService.data.member;
    this.team = this.editFormCommunicatorService.data.team;

    this.form = new EditTeamMemberRoleForm(this.teamMember);
  }

  selectRole(role: RoleType) {
    this.form.form.controls['role'].setValue(role);
  }

  submit() {
    if (!this.form.valid()) {
        return;
    }

    this.teamsService.editTeamMemberRole(`${this.team.id}`, `${this.teamMember.member.id}`, this.form).subscribe((team: Team) => {
        this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditTeamMember);
    });
  }

  delete() {
    this.teamsService.removeTeamMember(`${this.team.id}`, `${this.teamMember.member.id}`).subscribe((team: Team) => {
      this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditTeamMember);
      this.editFormCommunicatorService.closeForm();
    });
  }

}
