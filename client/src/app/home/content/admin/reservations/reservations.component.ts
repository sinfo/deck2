import { Component, OnInit } from '@angular/core';

import { Subscription } from 'rxjs/internal/Subscription';
import { Observable } from 'rxjs/internal/Observable';

import { debounceTime, map } from 'rxjs/operators';

import { VenuesService } from 'src/app/views/admin/venues/venues.service';
import { ReservationsService } from 'src/app/views/admin/reservations/reservations.service';
import { DeckService } from 'src/app/services/deck.service';
import { LinksService } from 'src/app/views/admin/links/links.service';
import { CanvasService } from 'src/app/views/admin/venues/venue/venue-image/canvas/canvas.service';

import { Reservation } from 'src/app/views/admin/reservations/reservation/reservation';
import { Event } from 'src/app/models/event';
import { Company } from 'src/app/models/company';
import { Venue, Availability } from 'src/app/views/admin/venues/venue/venue';
import { CanvasState } from 'src/app/views/admin/venues/venue/venue-image/canvas/canvasCommunication';

@Component({
  selector: 'app-reservations',
  templateUrl: './reservations.component.html',
  styleUrls: ['./reservations.component.css']
})
export class ReservationsComponent implements OnInit {

  private canvasState: CanvasState = CanvasState.RESERVATIONS;

  event: Event;
  reservations: {
    all: Reservation[],
    confirmed: Reservation[],
    pending: Reservation[],
    cancelled: Reservation[]
  };
  private companies: Company[];
  venue: Venue;
  private availability: Availability;
  private day = 1;

  private eventSubscription: Subscription;
  private companiesSubscription: Subscription;
  private venuesSubscription: Subscription;
  private reservationsSubscription: Subscription;

  public filteredReservation: Reservation;

  constructor(
    private deckService: DeckService,
    private reservationsService: ReservationsService,
    private linksService: LinksService,
    private venuesService: VenuesService,
    private canvasService: CanvasService
  ) { }

  ngOnInit() {
    this.reservations = {
      all: [] as Reservation[],
      confirmed: [] as Reservation[],
      pending: [] as Reservation[],
      cancelled: [] as Reservation[]
    };

    this.eventSubscription = this.deckService.getEventSubject()
      .subscribe(event => {
        this.event = new Event(event);

        if (this.availability === undefined) {
          this.generateAvailability();
        }

        this.reservationsService.getFromEdition(event.id)
          .subscribe(reservations => this.reservationsService.setReservations(reservations));
      });

    this.venuesSubscription = this.venuesService.getVenueSubject()
      .subscribe(venue => {
        this.venue = venue;

        if (this.availability === undefined) {
          this.generateAvailability();
        }
      });

    this.reservationsSubscription = this.reservationsService.getReservationsSubject()
      .subscribe(_reservations => {
        const reservations = this.companies
          ? Reservation.fromArray(_reservations, this.companies)
          : Reservation.fromArray(_reservations);

        this.reservations = {
          all: reservations,
          pending: reservations.filter(r => r.isPending()) as Reservation[],
          confirmed: reservations.filter(r => r.isConfirmed()) as Reservation[],
          cancelled: reservations.filter(r => r.isCancelled()) as Reservation[]
        };

        this.generateAvailability();
      });

    this.availability = this.venuesService.getAvailability();

    this.companiesSubscription = this.linksService.getCompaniesSubscription()
      .subscribe(companies => {
        if (companies.all.length > 0) {
          this.companies = companies.all;

          if (this.reservations.all.length && this.reservations.all[0].company === undefined) {
            Reservation.updateArrayWithCompanyInfo(this.reservations.all, companies.all);
            Reservation.updateArrayWithCompanyInfo(this.reservations.pending, companies.all);
            Reservation.updateArrayWithCompanyInfo(this.reservations.confirmed, companies.all);
            Reservation.updateArrayWithCompanyInfo(this.reservations.cancelled, companies.all);
          }

          if (this.availability === undefined) {
            this.generateAvailability();
          }
        }
      });
  }

  search = (text$: Observable<string>) =>
    text$.pipe(
      debounceTime(200),
      map(term => term === ''
        ? []
        : this.reservations.all
          .reduce(this.filterCompaniesHelper(term), [])
          .slice(0, 10)
      )
    )

  formatter = (r: Reservation) => r.company.name;

  // TODO is currI necessary
  private filterCompaniesHelper(company: string) {
    return function (total: Reservation[], curr: Reservation, currI: number, arr: Reservation[]): Reservation[] {
      let filter = curr.company.name.toLowerCase().indexOf(company.toLowerCase()) > -1;
      filter = filter && total.filter(r => r.company.name === curr.company.name).length === 0;

      if (filter) { total.push(curr); }

      return total;
    };
  }

  private generateAvailability() {
    if (this.event && this.venue && this.reservations && this.companies) {
      this.availability = Availability.generate(
        this.event, this.venue, this.reservations.all, this.companies
      );

      this.venuesService.setAvailability(this.availability);
      this.canvasService.selectDay(1);

    } else {
      this.availability = undefined;
    }
  }

  private changeDay(day: number) {
    this.canvasService.selectDay(day);
  }

  private confirmationBlocked(reservation: Reservation): boolean {
    return !reservation.canbeConfirmed(this.reservations.confirmed);
  }

}
