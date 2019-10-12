import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';

import { environment } from 'environments/environment';

import { Contact, EditContactForm } from '../models/contact';

import { AuthService } from './auth.service';

@Injectable({
    providedIn: 'root'
})
export class ContactsService {

    private headers: HttpHeaders;
    private url: String = `${environment.deck2}/contacts`;

    constructor(
        private http: HttpClient,
        private auth: AuthService
    ) {
        this.headers = this.auth.getHeaders();
    }

    getContact(contactID: String): Observable<Contact> {
        return this.http.get<Contact>(`${this.url}/${contactID}`, { headers: this.headers });
    }

    editContact(form: EditContactForm): Observable<Contact> {
        return this.http.put<Contact>(`${this.url}/${form.contactId}`, form.value(), { headers: this.headers });
    }
}
