import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';
import { of } from 'rxjs/internal/observable/of';
import { map } from 'rxjs/operators';

import { environment } from 'environments/environment';

import { AuthService } from './auth.service';

import { Company } from '../models/company';
import { FilterCompany } from '../home/content/filter/filter';

@Injectable({
    providedIn: 'root'
})
export class CompaniesService {

    private companies: Company[];

    private headers: HttpHeaders;
    private url: String = `${environment.deck2}/companies`;

    constructor(
        private http: HttpClient,
        private auth: AuthService
    ) {
        this.headers = this.auth.getHeaders();
    }

    getCompanies(filterCompany?: FilterCompany): Observable<Company[]> {

        const filterHasContent = filterCompany !== undefined && filterCompany.hasContent();

        if (!filterHasContent && this.companies !== undefined) {
            return of(this.companies);
        }

        const params = filterHasContent ? filterCompany.getHttpQuery() : new HttpParams();
        return this.http.get<Company[]>(`${this.url}`, { params: params, headers: this.headers }).pipe(
            map((companies: Company[]) => {
                if (!filterHasContent && this.companies === undefined) {
                    this.companies = companies;
                }

                return companies;
            })
        );

    }

    getCompany(companyID: string): Observable<Company> {
        return this.http.get<Company>(`${this.url}/${companyID}`, { headers: this.headers });
    }

}
