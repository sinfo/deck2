import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';
import { of } from 'rxjs/internal/observable/of';
import { map } from 'rxjs/operators';

import { environment } from 'environments/environment';

import { Event, EventComparator } from '../models/event';

import { AuthService } from './auth.service';

@Injectable({
    providedIn: 'root'
})
export class EventsService {

    private currentEvent: Event;
    private events: Event[];

    private headers: HttpHeaders;
    private url: String = `${environment.deck2}/events`;

    constructor(
        private http: HttpClient,
        private auth: AuthService
    ) {
        this.headers = this.auth.getHeaders();
        this.getEvents();
    }

    getEvents(forceFetch?: boolean): Observable<Event[]> {

        if (this.events !== undefined && !forceFetch) {
            return of(this.events);
        }

        return this.http.get<Event[]>(`${this.url}`, { headers: this.headers }).pipe(
            map((events: Event[]) => {
                this.events = events;

                const sorted = events.sort(EventComparator);
                this.currentEvent = sorted[0];

                return events;
            })
        );
    }

    getCurrentEvent(): Observable<Event> {

        if (this.currentEvent !== undefined) {
            return of(this.currentEvent);
        }

        return this.getEvents().pipe(
            map((events: Event[]): Event => {
                const sorted = events.sort(EventComparator);
                this.currentEvent = sorted[0];
                return sorted[0];
            })
        );

    }

    addItem(itemID: string): Observable<Event> {
        return this.http.post<Event>(`${this.url}/items`, { item: itemID }, { headers: this.headers });
    }

    removeItem(itemID: string): Observable<Event> {
        return this.http.delete<Event>(`${this.url}/items/${itemID}`, { headers: this.headers });
    }

}
