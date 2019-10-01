import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';

import { environment } from 'environments/environment';

import { Company } from '../models/company';

import { AuthService } from './auth.service';

@Injectable({
    providedIn: 'root'
})
export class CompaniesService {

    private headers: HttpHeaders;
    private url: String = `${environment.deck2}/companies`;

    constructor(
        private http: HttpClient,
        private auth: AuthService
    ) {
        this.headers = this.auth.getHeaders();
    }

    getCompanies(): Observable<Company[]> {
        return this.http.get<Company[]>(`${this.url}`, { headers: this.headers });
    }

}
