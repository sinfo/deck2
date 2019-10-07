import { Component, OnInit, OnDestroy } from '@angular/core';

import { EventsService } from '../../../deck-api/events.service';
import { MembersService } from '../../../deck-api/members.service';
import { FilterService } from '../filter/filter.service';
import { TeamsService } from '../../../deck-api/teams.service';

import { Member } from '../../../models/member';
import { Team, PopulatedTeam } from '../../../models/team';
import { FilterField, FilterType, Filters } from '../filter/filter';
import { Subscription } from 'rxjs';

@Component({
    selector: 'app-teams',
    templateUrl: './teams.component.html',
    styleUrls: ['./teams.component.css']
})
export class TeamsComponent implements OnInit, OnDestroy {

    teams: PopulatedTeam[];
    filterSubscription: Subscription;
    filters: Filters;

    constructor(
        private eventsService: EventsService,
        private teamsService: TeamsService,
        private membersService: MembersService,
        private filterService: FilterService
    ) {
        this.filterSubscription = this.filterService.getFiltersSubscription().subscribe((filters: Filters) => {
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

    ngOnDestroy() {
        this.filterSubscription.unsubscribe();
    }

    updateTeams() {
        this.teamsService.getTeams(this.filters.team).subscribe((teams: Team[]) => {
            this.teams = [];

            for (const team of teams) {
                const newTeam = new PopulatedTeam(team, this.membersService, () => {
                    this.teams.push(newTeam);
                });
            }
        });
    }

}
