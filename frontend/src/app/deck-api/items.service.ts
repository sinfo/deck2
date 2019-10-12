import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';
import { of } from 'rxjs/internal/observable/of';
import { map } from 'rxjs/operators';

import { environment } from 'environments/environment';

import { Item, AddItemForm } from '../models/item';
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

    getItems(filterItem?: FilterItem): Observable<Item[]> {
        const filterHasContent = filterItem !== undefined && filterItem.hasContent();

        if (!filterHasContent && this.items !== undefined) {
            return of(this.items);
        }

        const params = filterHasContent ? filterItem.getHttpQuery() : new HttpParams();
        return this.http.get<Item[]>(`${this.url}`, { params: params, headers: this.headers }).pipe(
            map((items: Item[]) => {
                if (!filterHasContent && this.items === undefined) {
                    this.items = items;
                }

                return items;
            })
        );
    }

    getItem(ItemID: string): Observable<Item> {
        return this.http.get<Item>(`${this.url}/${ItemID}`, { headers: this.headers });
    }

    createItem(form: AddItemForm): Observable<Item> {
        return this.http.post<Item>(`${this.url}`, form.value(), { headers: this.headers });
    }
}
