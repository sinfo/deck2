import { HttpParams } from '@angular/common/http';

import { EventsService } from '../../../deck-api/events.service';
import { Event, EventComparator } from '../../../models/event';

export enum FilterField {
    Status = 'status',
    Name = 'name',
    Event = 'event',
    MemberName = 'memberName',
}

export enum FilterType {
    Member,
    Speaker,
    Team,
}

class Field<T> {
    name: FilterField;

    // if this should enter on an http query
    // (some fields are supposed to be used to filter on client side)
    // by default, this is true
    httpQuery: boolean;

    set: boolean;
    value: T;
    isDefaultValue: boolean;

    // default value when none is set
    // this means that this field *always* set
    default: T;

    options: T[];

    constructor(name: FilterField, value: T, options: T[], optional?: { httpQuery?: boolean, default?: T }) {
        this.name = name;
        this.set = false;
        this.value = value;
        this.options = options;
        this.isDefaultValue = false;

        this.httpQuery = optional && optional.httpQuery !== undefined ? optional.httpQuery : true;

        if (optional && optional.default !== undefined) {
            this.default = optional.default;
        }
    }

    setDefault(_default: T) {
        this.default = _default;
        if (!this.set) {
            this.value = _default;
            this.set = true;
            this.isDefaultValue = true;
        }
    }

    hasDefault(): boolean {
        return this.default !== undefined;
    }

    copy(filter: Field<T>) {
        this.name = filter.name;
        this.httpQuery = filter.httpQuery;
        this.set = filter.set;
        this.value = filter.value;
        this.options = filter.options;
    }
}

abstract class Filter {

    protected fields: Field<any>[];

    constructor() {
        this.fields = [];
    }

    protected addField<T>(name: FilterField, value: T, options: T[], optional?: { httpQuery?: boolean, default?: T }) {
        this.fields.push(new Field<T>(name, value, options, optional));
    }

    isSet(name: FilterField) {
        for (const field of this.fields) {
            if (field.name === name) {
                return field.set;
            }
        }

        return false;
    }

    isDefaultValue(name: FilterField): boolean {
        for (const field of this.fields) {
            if (field.name !== name) { continue; }

            return field.isDefaultValue;
        }

        return false;
    }

    setValue(name: FilterField, value: any, defaultCondition?: boolean) {
        for (const field of this.fields) {
            if (field.name !== name) { continue; }

            if (value === null && field.hasDefault()) {
                if (defaultCondition || defaultCondition === undefined) {
                    field.value = field.default;
                    field.set = true;
                    field.isDefaultValue = true;
                } else {
                    field.set = false;
                    field.isDefaultValue = false;
                }

                return;
            }

            field.set = (value !== null);

            if (value !== null) {
                field.value = value;
                field.isDefaultValue = false;
            }
        }
    }

    getValue(name: FilterField) {
        for (const field of this.fields) {
            if (field.name === name) { return field.value; }
        }
        return null;
    }

    getOptions(name: FilterField) {
        for (const field of this.fields) {
            if (field.name === name) { return field.options; }
        }
        return null;
    }

    hasHttpQueryContent() {
        for (const field of this.fields) {
            if (field.httpQuery && field.set) {
                return true;
            }
        }

        return false;
    }

    getHttpQuery() {
        const options = {};

        for (const field of this.fields) {
            if (field.httpQuery && field.set) {
                options[field.name] = field.value;
            }
        }

        return new HttpParams({ fromObject: options });
    }

    hasContent() {
        for (const field of this.fields) {
            if (field.set) {
                return true;
            }
        }

        return false;
    }

    abstract duplicate(): Filter;

    protected copyFields(filter: Filter) {
        for (const copyField of this.fields) {
            for (const filterField of filter.fields) {
                if (copyField.name === filterField.name) {
                    copyField.copy(filterField);
                }
            }
        }
    }
}

export type FiltersInitCallback = () => void;
type FilterConstructorCallback = (instance: Filter) => void;

export class FilterSpeaker extends Filter {

    constructor(protected eventsService: EventsService, callback?: FilterConstructorCallback) {
        super();

        this.addField<string>(FilterField.Status, null, [
            'SUGGESTED', 'SELECTED', 'ON_HOLD',
            'CONTACTED', 'IN_CONVERSATIONS', 'ACCEPTED',
            'REJECTED', 'GIVEN_UP', 'ANNOUNCED'
        ], { httpQuery: false });

        this.addField<string>(FilterField.Name, null, []);
        this.addField<number>(FilterField.Event, null, []);

        this.eventsService.getEvents().subscribe((events: Event[]) => {
            for (const field of this.fields) {
                if (field.name === FilterField.Event) {
                    field.options = events.sort(EventComparator).map((event: Event) => +event.id);
                    break;
                }
            }

            this.eventsService.getCurrentEvent().subscribe((event: Event) => {
                for (const field of this.fields) {
                    if (field.name === FilterField.Event) {
                        field.setDefault(+event.id);
                        break;
                    }
                }

                if (callback) { callback(this); }
            });
        });
    }

    duplicate(): FilterSpeaker {
        const copy = new FilterSpeaker(this.eventsService);
        copy.copyFields(this);
        return copy;
    }
}

export class FilterTeam extends Filter {
    constructor(protected eventsService: EventsService, callback?: FilterConstructorCallback) {
        super();

        this.addField<string>(FilterField.Name, null, []);
        this.addField<number>(FilterField.Event, null, []);
        this.addField<string>(FilterField.MemberName, null, []);

        this.eventsService.getEvents().subscribe((events: Event[]) => {
            for (const field of this.fields) {
                if (field.name === FilterField.Event) {
                    field.options = events.sort(EventComparator).map((event: Event) => +event.id);
                    break;
                }
            }

            this.eventsService.getCurrentEvent().subscribe((event: Event) => {
                for (const field of this.fields) {
                    if (field.name === FilterField.Event) {
                        field.setDefault(+event.id);
                        break;
                    }
                }

                if (callback) { callback(this); }
            });
        });
    }

    duplicate(): FilterTeam {
        const copy = new FilterTeam(this.eventsService);
        copy.copyFields(this);
        return copy;
    }
}

export class FilterMember extends Filter {
    constructor(protected eventsService: EventsService, callback?: FilterConstructorCallback) {
        super();

        this.addField<string>(FilterField.Name, null, []);
        this.addField<number>(FilterField.Event, null, []);

        this.eventsService.getEvents().subscribe((events: Event[]) => {
            for (const field of this.fields) {
                if (field.name === FilterField.Event) {
                    field.options = events.sort(EventComparator).map((event: Event) => +event.id);
                    break;
                }
            }

            this.eventsService.getCurrentEvent().subscribe((event: Event) => {
                for (const field of this.fields) {
                    if (field.name === FilterField.Event) {
                        field.setDefault(+event.id);
                        break;
                    }
                }

                if (callback) { callback(this); }
            });
        });
    }

    duplicate(): FilterMember {
        const copy = new FilterMember(this.eventsService);
        copy.copyFields(this);
        return copy;
    }
}

export class Filters {

    primary: FilterType;

    member: FilterMember;
    speaker: FilterSpeaker;
    team: FilterTeam;

    constructor(private eventsService: EventsService) { }

    initFilters(primaryType: FilterType, secondaryTypes: FilterType[], callback?: FiltersInitCallback) {
        this.initFilter(primaryType, () => {
            this.primary = primaryType;
            this.initSecondaryFilters(secondaryTypes, callback);
        });
    }

    initSecondaryFilters(types: FilterType[], callback?: FiltersInitCallback) {
        if (!types.length && callback) {
            return callback();
        }

        const filterType = types.shift();
        this.initFilter(filterType, () => { this.initSecondaryFilters(types, callback); });
    }

    private initFilter(filterType: FilterType, callback?: FiltersInitCallback) {
        switch (filterType) {
            case FilterType.Member:
                return new FilterMember(this.eventsService, (instance: FilterMember) => {
                    this.member = instance;
                    if (callback) { callback(); }
                });

            case FilterType.Speaker:
                return new FilterSpeaker(this.eventsService, (instance: FilterSpeaker) => {
                    this.speaker = instance;
                    if (callback) { callback(); }
                });

            case FilterType.Team:
                return new FilterTeam(this.eventsService, (instance: FilterTeam) => {
                    this.team = instance;
                    if (callback) { callback(); }
                });

            default:
                if (callback) { callback(); }
        }
    }

    isPrimaryFilterSpeaker(): boolean {
        return this.primary === FilterType.Speaker;
    }

    isPrimaryFilterMember(): boolean {
        return this.primary === FilterType.Member;
    }

    isPrimaryFilterTeam(): boolean {
        return this.primary === FilterType.Team;
    }
}
