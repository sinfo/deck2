import { Component, OnInit } from '@angular/core';

import { SpeakersService } from '../../../deck-api/speakers.service';
import { EventsService } from '../../../deck-api/events.service';
import { MembersService } from '../../../deck-api/members.service';
import { FilterService } from '../filter/filter.service';

import { Speaker, SpeakerParticipation } from '../../../models/speaker';
import { Member } from '../../../models/member';
import { FilterField, FilterType, Filters } from '../filter/filter';

@Component({
    selector: 'app-items',
    templateUrl: './items.component.html',
    styleUrls: ['./items.component.css']
})
export class ItemsComponent implements OnInit {

    constructor() { }

    ngOnInit() {
    }

}
