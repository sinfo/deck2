import { Component, OnInit } from '@angular/core';

import { EventsService } from '../../../deck-api/events.service';
import { ItemsService } from '../../../deck-api/items.service';
import { FilterService } from '../filter/filter.service';

import { Item } from '../../../models/item';
import { FilterField, FilterType, Filters } from '../filter/filter';

@Component({
    selector: 'app-items',
    templateUrl: './items.component.html',
    styleUrls: ['./items.component.css']
})
export class ItemsComponent implements OnInit {

    filters: Filters;

    private items: Item[];

    constructor(
        private filterService: FilterService,
        private itemsService: ItemsService,
        private eventsService: EventsService
    ) {
        this.filterService.getFiltersSubscription().subscribe((filters: Filters) => {
            this.filters = filters;
            this.fetchItems();
        });
    }

    ngOnInit() {
        this.filters = new Filters(this.eventsService);
        this.filters.initFilters(FilterType.Item, [], () => {
            this.fetchItems();
        });
    }

    fetchItems() {
        this.itemsService.getItems(this.filters.item).subscribe((items: Item[]) => {
            this.items = items;
        });
    }

}
