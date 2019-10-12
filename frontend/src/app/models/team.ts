import { FormControl, FormGroup, Validators, ValidatorFn, AbstractControl } from '@angular/forms';

import { Member } from './member';
import { Meeting } from './meeting';

import { MembersService } from '../deck-api/members.service';
import { RoleType, RoleComparator } from './role';

export class Team {
    id: String;
    name: String;
    members: TeamMember[];
    meetings: String[];
}

export class TeamMember {
    member: String;
    role: RoleType;
}

declare type PopulatedTeamCallback = (team: PopulatedTeam) => void;

export class PopulatedTeamMember {
    member: Member;
    role: RoleType;

    constructor(member: Member, role: RoleType) {
        this.member = member;
        this.role = role;
    }
}

export class PopulatedTeam {
    id: String;
    name: String;
    members: PopulatedTeamMember[];
    meetings: Meeting[];

    constructor(
        team: Team,
        membersService: MembersService,
        callback?: PopulatedTeamCallback
    ) {
        this.id = team.id;
        this.name = team.name;
        this.members = [];
        this.meetings = [];

        for (const teamMember of team.members) {
            membersService.getMember(teamMember.member).subscribe((member: Member) => {
                this.members.push(new PopulatedTeamMember(member, teamMember.role));
                if (this.members.length === team.members.length && callback) {
                    this.members.sort(PopulatedTeamMemberComparator);
                    callback(this);
                }
            });
        }

        if (this.members.length === team.members.length && callback) {
            callback(this);
        }

        // TODO: fill meetings
    }
}

export function PopulatedTeamMemberComparator(m1: PopulatedTeamMember, m2: PopulatedTeamMember) {
    if (m1.role === m2.role) {
        return m1.member.name.localeCompare(`${m2.member.name}`);
    }

    return RoleComparator(m1.role, m2.role);
}

export class AddTeamForm {

    form: FormGroup;

    constructor() {
        this.form = new FormGroup({
            name: new FormControl('', [Validators.required, Validators.minLength(1)]),
        });
    }

    value() {
        return this.form.value;
    }

    valid() {
        return this.form.valid;
    }
}

export function roleValidator(options: RoleType[]): ValidatorFn {
    return (control: AbstractControl): { [key: string]: any } | null => {
        for (const option of options) {
            if (control.value === option) {
                return null;
            }
        }

        return { 'invalidOption': { value: control.value } };
    };
}

export class AddMemberToTeamForm {

    form: FormGroup;
    roleOptions: RoleType[] = [RoleType.MEMBER, RoleType.TEAM_LEADER, RoleType.COORDINATOR, RoleType.ADMIN];

    constructor() {
        this.form = new FormGroup({
            member: new FormControl('', [Validators.required, Validators.minLength(1)]),
            role: new FormControl('', [Validators.required, Validators.minLength(1), roleValidator(this.roleOptions)]),
        });
    }

    getRoleOptions() {
        return this.roleOptions;
    }

    valid() {
        return this.form.valid;
    }

    value() {
        return this.form.value;
    }
}
