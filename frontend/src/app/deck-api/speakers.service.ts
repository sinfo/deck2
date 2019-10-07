import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';
import { of } from 'rxjs/internal/observable/of';
import { map } from 'rxjs/operators';

import { environment } from 'environments/environment';

import {
    EditSpeakerForm,
    EditSpeakerImageForm,
    EditSpeakerParticipationForm,
    Speaker,
    SpeakerParticipationValidStatusSteps,
    AddSpeakerForm
} from '../models/speaker';
import { FilterSpeaker } from '../home/content/filter/filter';

import { AuthService } from './auth.service';
import { AddThreadForm } from '../models/thread';

@Injectable({
    providedIn: 'root'
})
export class SpeakersService {

    private speakers: Speaker[];

    private headers: HttpHeaders;
    private url: String = `${environment.deck2}/speakers`;

    constructor(
        private http: HttpClient,
        private auth: AuthService
    ) {
        this.headers = this.auth.getHeaders();
    }

    getSpeakers(filterSpeaker?: FilterSpeaker): Observable<Speaker[]> {

        const filterHasContent = filterSpeaker !== undefined && filterSpeaker.hasContent();

        if (!filterHasContent && this.speakers !== undefined) {
            return of(this.speakers);
        }

        const params = filterHasContent ? filterSpeaker.getHttpQuery() : new HttpParams();
        return this.http.get<Speaker[]>(`${this.url}`, { params: params, headers: this.headers }).pipe(
            map((speakers: Speaker[]) => {
                if (!filterHasContent && this.speakers === undefined) {
                    this.speakers = speakers;
                }

                return speakers;
            })
        );

    }

    getSpeaker(speakerID: string): Observable<Speaker> {
        return this.http.get<Speaker>(`${this.url}/${speakerID}`, { headers: this.headers });
    }

    createSpeaker(form: AddSpeakerForm): Observable<Speaker> {
        return this.http.post<Speaker>(`${this.url}`, form.value(), { headers: this.headers });
    }

    editSpeaker(speakerID: string, form: EditSpeakerForm): Observable<Speaker> {
        return this.http.put<Speaker>(`${this.url}/${speakerID}`, form.value(), { headers: this.headers });
    }

    editSpeakerParticipation(speakerID: string, form: EditSpeakerParticipationForm): Observable<Speaker> {
        return this.http.put<Speaker>(`${this.url}/${speakerID}/participation`, form.value(), { headers: this.headers });
    }

    addSpeakerParticipation(speakerID: string): Observable<Speaker> {
        return this.http.post<Speaker>(`${this.url}/${speakerID}/participation`, null, { headers: this.headers });
    }

    editSpeakerInternalImage(speakerID: string, form: EditSpeakerImageForm): Observable<Speaker> {
        const formData = new FormData();
        formData.append('image', form.value(), form.value().name);
        return this.http.post<Speaker>(`${this.url}/${speakerID}/image/internal`,
            formData,
            {
                headers: new HttpHeaders({ 'Authorization': this.headers.get('Authorization') })
            }
        );
    }

    editSpeakerPublicImage(speakerID: string, form: EditSpeakerImageForm): Observable<Speaker> {
        const formData = new FormData();
        formData.append('image', form.value(), form.value().name);
        return this.http.post<Speaker>(`${this.url}/${speakerID}/image/speaker`,
            formData,
            {
                headers: new HttpHeaders({ 'Authorization': this.headers.get('Authorization') })
            }
        );
    }

    editSpeakerCompanyImage(speakerID: string, form: EditSpeakerImageForm): Observable<Speaker> {
        const formData = new FormData();
        formData.append('image', form.value(), form.value().name);
        return this.http.post<Speaker>(`${this.url}/${speakerID}/image/company`,
            formData,
            {
                headers: new HttpHeaders({ 'Authorization': this.headers.get('Authorization') })
            }
        );
    }

    getValidStatusSteps(speakerID: string): Observable<SpeakerParticipationValidStatusSteps> {
        return this.http.get<SpeakerParticipationValidStatusSteps>(
            `${this.url}/${speakerID}/participation/status/next`, { headers: this.headers });
    }

    stepStatus(speakerID: string, step: number): Observable<Speaker> {
        return this.http.post<Speaker>(`${this.url}/${speakerID}/participation/status/${step}`, null, { headers: this.headers });
    }

    addThread(speakerID: string, form: AddThreadForm): Observable<Speaker> {
        return this.http.post<Speaker>(`${this.url}/${speakerID}/thread`, form.value(), { headers: this.headers });
    }

    subscribe(speakerID: String): Observable<Speaker> {
        return this.http.put<Speaker>(`${this.url}/${speakerID}/subscribe`, null, { headers: this.headers });
    }

    unsubscribe(speakerID: String): Observable<Speaker> {
        return this.http.put<Speaker>(`${this.url}/${speakerID}/unsubscribe`, null, { headers: this.headers });
    }

}
