import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';
import { of } from 'rxjs/internal/observable/of';
import { map } from 'rxjs/operators';

import { environment } from 'environments/environment';

import { Item } from '../models/item';
import { FilterItem } from '../home/content/filter/filter';

import { AuthService } from './auth.service';

@Injectable({
    providedIn: 'root'
})
export class ItemsService {

    private items: Item[];

    private headers: HttpHeaders;
    private url: String = `${environment.deck2}/items`;

    constructor(
        private http: HttpClient,
        private auth: AuthService
    ) {
        this.headers = this.auth.getHeaders();
    }
}
