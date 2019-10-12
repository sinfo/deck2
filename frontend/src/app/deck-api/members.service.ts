import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';
import { of } from 'rxjs/internal/observable/of';
import { map } from 'rxjs/operators';

import { environment } from 'environments/environment';

import { Member } from '../models/member';
import { Role } from '../models/role';
import { FilterMember } from '../home/content/filter/filter';

import { AuthService } from './auth.service';

@Injectable({
    providedIn: 'root'
})
export class MembersService {

    private members: Member[];

    private headers: HttpHeaders;
    private url: String = `${environment.deck2}/members`;

    constructor(
        private http: HttpClient,
        private auth: AuthService
    ) {
        this.headers = this.auth.getHeaders();
    }

    getMembers(filterMember?: FilterMember): Observable<Member[]> {

        const filterHasContent = filterMember !== undefined && filterMember.hasHttpQueryContent();

        if (!filterHasContent && this.members !== undefined) {
            return of(this.members);
        }

        const params = filterHasContent ? filterMember.getHttpQuery() : new HttpParams();
        return this.http.get<Member[]>(`${this.url}`, { params: params, headers: this.headers }).pipe(
            map((members: Member[]) => {
                if (!filterHasContent && this.members === undefined) {
                    this.members = members;
                }

                return members;
            })
        );

    }

    getMember(memberID: String): Observable<Member> {
        return this.http.get<Member>(`${this.url}/${memberID}`, { headers: this.headers });
    }

    getRole(memberID: String): Observable<Role> {
        return this.http.get<Role>(`${this.url}/${memberID}/role`, { headers: this.headers });
    }

}
