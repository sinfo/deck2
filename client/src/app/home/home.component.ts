import { Component, OnInit } from '@angular/core';

import { MeService } from '../deck-api/me.service';
import { EventsService } from '../deck-api/events.service';

import { Member } from '../models/member';
import { Event } from '../models/event';

@Component({
    selector: 'app-home',
    templateUrl: './home.component.html',
    styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit {

    darkMode: boolean;

    me: Member;

    events: Event[];
    currentEvent: Event;

    constructor(
        private meService: MeService,
        private eventsService: EventsService,
    ) {
    }

    ngOnInit() {
        this.darkMode = false;

        this.meService.getMe().subscribe((member: Member) => {
            this.me = member;
        });

        this.eventsService.getEvents().subscribe((events: Event[]) => {
            this.events = events;
        });

        this.eventsService.getCurrentEvent().subscribe((event: Event) => {
            this.currentEvent = event;
        });
    }

}
