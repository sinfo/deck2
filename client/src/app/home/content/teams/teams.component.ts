import { Component, OnInit } from '@angular/core';

import { SpeakersService } from '../../../deck-api/speakers.service';
import { EventsService } from '../../../deck-api/events.service';
import { MembersService } from '../../../deck-api/members.service';
import { FilterService } from '../filter/filter.service';
import { TeamsService } from '../../../deck-api/teams.service';

import { Member } from '../../../models/member';
import { Team, PopulatedTeam } from '../../../models/team';
import { FilterField, FilterType, Filters } from '../filter/filter';

@Component({
    selector: 'app-teams',
    templateUrl: './teams.component.html',
    styleUrls: ['./teams.component.css']
})
export class TeamsComponent implements OnInit {

    teams: PopulatedTeam[];
    filters: Filters;

    constructor(
        private eventsService: EventsService,
        private teamsService: TeamsService,
        private membersService: MembersService,
        private filterService: FilterService
    ) {
        this.filterService.getFiltersSubscription().subscribe((filters: Filters) => {
            this.filters.team = filters.team;
            this.updateTeams();
        });
    }

    ngOnInit() {
        this.filters = new Filters(this.eventsService);
        this.filters.initFilters(FilterType.Team, [], () => {
            this.updateTeams();
        });
    }

    updateTeams() {
        this.teamsService.getTeams(this.filters.team).subscribe((teams: Team[]) => {
            this.teams = [];

            for (const team of teams) {
                const newTeam = new PopulatedTeam(team, this.membersService, () => {
                    this.teams.push(newTeam);
                    console.log(newTeam);
                });
            }
        });
    }

}
