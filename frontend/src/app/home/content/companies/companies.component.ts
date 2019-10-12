import { Component, OnInit, OnDestroy } from '@angular/core';

import { CompaniesService } from '../../../deck-api/companies.service';
import { EventsService } from '../../../deck-api/events.service';
import { MembersService } from '../../../deck-api/members.service';
import { FilterService } from '../filter/filter.service';

import { Company, CompanyParticipation } from '../../../models/company';
import { Member } from '../../../models/member';
import { FilterField, FilterType, Filters } from '../filter/filter';
import { Subscription } from 'rxjs';

@Component({
    selector: 'app-companies',
    templateUrl: './companies.component.html',
    styleUrls: ['./companies.component.css']
})
export class CompaniesComponent implements OnInit, OnDestroy {

    filterSubscription: Subscription;
    filters: Filters;

    private companies: Company[];
    private members: Member[];

    companiesByMember: {
        member: Member,
        companies: {
            company: Company,
            participation: CompanyParticipation
        }[]
    }[];

    constructor(
        private eventsService: EventsService,
        private companiesService: CompaniesService,
        private membersService: MembersService,
        private filterService: FilterService,
    ) {
        this.filterSubscription = this.filterService.getFiltersSubscription().subscribe((filters: Filters) => {
            this.filters = filters;
            this.fetchAndFilterCompanies();
        });
    }

    ngOnInit() {
        this.filters = new Filters(this.eventsService);
        this.filters.initFilters(FilterType.Company, [FilterType.Member], () => {
            this.fetchAndFilterCompanies();
        });
    }

    ngOnDestroy() {
        this.filterSubscription.unsubscribe();
    }

    fetchAndFilterCompanies() {
        this.companiesByMember = [];

        this.membersService.getMembers(this.filters.member).subscribe((members: Member[]) => {
            this.members = members;

            this.companiesService.getCompanies(this.filters.company).subscribe((companies: Company[]) => {
                this.companies = companies;
                this.companiesByMember = [];

                this.filterCompanies();
            });
        });
    }

    private filterCompanies() {
        const eventID = this.filters.company.getValue(FilterField.Event);

        for (const company of this.companies) {
            const filteredParticipations = company.participations.filter((p: CompanyParticipation) => {
                if (!this.filters.company.isSet(FilterField.Name) && p.event !== eventID) { return false; }
                if (this.filters.company.isSet(FilterField.Status)) {
                    return this.filters.company.getValue(FilterField.Status) === p.status;
                }
                return true;
            });

            const participation = filteredParticipations.length ? filteredParticipations[filteredParticipations.length - 1] : null;
            if (participation === null && this.filters.company.isSet(FilterField.Status)) { continue; }

            const filteredMembers = participation ? this.members.filter((m: Member) => {
                return m.id === participation.member;
            }) : [];

            const member = filteredMembers.length ? filteredMembers[0] : null;

            if (this.filters.member.isSet(FilterField.Name) && member === null) { continue; }
            this.addCompanyToMember(company, participation, member);
        }

        this.companiesByMember.sort((a, b) => {
            if (a.member === null) { return -1; }
            if (b.member === null) { return 1; }
            return (a.member.name > b.member.name) ? 1 : ((b.member.name > a.member.name) ? -1 : 0)
        });
    }

    private addCompanyToMember(company: Company, participation: CompanyParticipation, member: Member) {

        let found = false;
        for (const savedCompany of this.companiesByMember) {
            if (savedCompany.member === member) {
                savedCompany.companies.push({
                    company: company,
                    participation: participation
                });
                found = true;
                break;
            }
        }

        if (!found) {
            this.companiesByMember.push({
                member: member,
                companies: [{
                    company: company,
                    participation: participation
                }]
            });
        }
    }

}
