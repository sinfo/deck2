import { Injectable } from '@angular/core';

import { ReplaySubject } from 'rxjs/internal/ReplaySubject';
import { Observable } from 'rxjs/internal/Observable';

import { FilterSpeaker, FilterMember, Filters } from './filter';

@Injectable({
    providedIn: 'root'
})
export class FilterService {

    private filtersSubject: ReplaySubject<Filters> = new ReplaySubject<Filters>();

    constructor() {
    }

    getFiltersSubscription(): Observable<Filters> {
        return this.filtersSubject.asObservable();
    }

    changeFilters(filters: Filters) {
        this.filtersSubject.next(filters);
    }

}
