import { Member } from './member';
import { Meeting } from './meeting';

import { MembersService } from '../deck-api/members.service';

export class Team {
    id: String;
    name: String;
    members: TeamMember[];
    meetings: String[];
}

export class TeamMember {
    member: String;
    role: String;
}

declare type PopulatedTeamCallback = () => void;

export class PopulatedTeamMember {
    member: Member;
    role: String;

    constructor(member: Member, role: String) {
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
                    callback();
                }
            });
        }

        // TODO: fill meetings
    }
}
