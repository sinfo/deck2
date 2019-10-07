import { Component, OnInit, OnDestroy, ViewContainerRef } from '@angular/core';

import { Subscription } from 'rxjs';

import { EventsService } from '../../../deck-api/events.service';
import { MembersService } from '../../../deck-api/members.service';
import { FilterService } from '../filter/filter.service';
import { TeamsService } from '../../../deck-api/teams.service';
import { ThemeService } from '../../../theme.service';
import { EditFormService } from '../../../templates/edit-form/edit-form.service';

import { Member } from '../../../models/member';
import { Team, PopulatedTeam } from '../../../models/team';
import { FilterField, FilterType, Filters } from '../filter/filter';
import { Theme } from '../../../theme';
import { AppliedForm } from '../../../templates/edit-form/edit-form-communicator.service';

@Component({
    selector: 'app-teams',
    templateUrl: './teams.component.html',
    styleUrls: ['./teams.component.css']
})
export class TeamsComponent implements OnInit, OnDestroy {

    teams: PopulatedTeam[];
    filterSubscription: Subscription;
    filters: Filters;

    darkMode: boolean;

    constructor(
        private eventsService: EventsService,
        private teamsService: TeamsService,
        private membersService: MembersService,
        private filterService: FilterService,
        private themeService: ThemeService,
        private editFormService: EditFormService,
        public vcRef: ViewContainerRef
    ) {
        this.filterSubscription = this.filterService.getFiltersSubscription().subscribe((filters: Filters) => {
            this.filters.team = filters.team;
            this.updateTeams();
        });

        const result = this.themeService.getThemeSubscription();
        this.darkMode = result.active.dark;
        result.subscription.subscribe((theme: Theme) => {
            this.darkMode = theme.dark;
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

    addMember(team: PopulatedTeam) {
        this.editFormService.showAddMemberToTeamForm(this.vcRef, team, (appliedForm: AppliedForm) => {
            this.updateTeams();
        });
    }

}
