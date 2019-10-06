import { Component, OnInit, OnDestroy } from '@angular/core';

import { Subscription } from 'rxjs/internal/Subscription';

import { VenuesService } from './services/venues.service';
import { DeckService } from '../../services/deck.service';

import { Event } from '../../../models/event';
import { Venue } from './models/venue';

@Component({
  selector: 'app-admin',
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.css']
})
export class AdminComponent implements OnInit, OnDestroy {

  event: Event;

  private eventSubscription: Subscription;
  private events: [Event];
  private venue: Venue;

  constructor(
    private deckService: DeckService,
    private venuesService: VenuesService
  ) { }

  ngOnInit() {
    this.venuesService.getVenue().subscribe(
      venue => this.updateData(venue),
      () => this.deckService.updateEvent()
    );

    this.eventSubscription = this.deckService.getEventSubject()
      .subscribe(event => {
        if (this.event === undefined || this.event.id !== event.id) {
          this.event = event;
          this.events = this.deckService.events;

          this.venuesService.getVenue(event.id).subscribe(
            venue => this.updateData(venue),
            () => this.updateData(null)
          );
        }
      });
  }

  ngOnDestroy() {
    this.eventSubscription.unsubscribe();
  }

  private switchEvent(edition: string) {
    this.deckService.updateEvent(edition);
  }

  private updateData(venue: Venue) {
    this.venue = venue;
    this.venuesService.setVenue(venue);
  }

}
