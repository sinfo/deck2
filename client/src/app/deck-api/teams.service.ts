import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';
import { of } from 'rxjs/internal/observable/of';
import { map } from 'rxjs/operators';

import { environment } from 'environments/environment';

import { Team } from '../models/team';
import { FilterTeam } from '../home/content/filter/filter';

import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class TeamsService {

  private teams: Team[];

  private headers: HttpHeaders;
  private url: String = `${environment.deck2}/teams`;

  constructor(
    private http: HttpClient,
    private auth: AuthService
  ) {
    this.headers = this.auth.getHeaders();
  }

  getTeams(filterTeam?: FilterTeam): Observable<Team[]> {
    const filterHasContent = filterTeam !== undefined && filterTeam.hasContent();

    if (!filterHasContent && this.teams !== undefined) {
      return of(this.teams);
    }

    const params = filterHasContent ? filterTeam.getHttpQuery() : new HttpParams();
    return this.http.get<Team[]>(`${this.url}`, { params: params, headers: this.headers }).pipe(
      map((teams: Team[]) => {
        if (!filterHasContent && this.teams === undefined) {
          this.teams = teams;
        }

        return teams;
      })
    );
  }

  getTeam(teamID: string): Observable<Team> {
    return this.http.get<Team>(`${this.url}/${teamID}`, { headers: this.headers });
  }
}
