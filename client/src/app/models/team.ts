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

declare type PopulatedTeamCallback = () => void;

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
                    callback();
                }
            });
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
