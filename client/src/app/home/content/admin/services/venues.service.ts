import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';
import { ReplaySubject } from 'rxjs/internal/ReplaySubject';

import { Venue, Availability } from '../models/venue';
import { Stand } from '../models/stand';
import { of } from 'rxjs';
import { SponsorsService } from '../../../services/sponsors.service';

@Injectable({
  providedIn: 'root'
})

export class VenuesService {
  private venue: Venue;
  private availability: Availability;

  private venueSubject: ReplaySubject<Venue>
    = new ReplaySubject<Venue>();

  private availabilitySubject: ReplaySubject<Availability>
    = new ReplaySubject<Availability>(null);

  constructor(
    private http: HttpClient,
    private sponsorsService: SponsorsService
  ) {

  }

  // ------------ Venue ------------

  getVenue(edition?: String): Observable<Venue> {
    if (this.venue && this.venue.edition === edition) {
      return of(this.venue);
    }

    if (edition === undefined) {
      return this.getCurrentVenue();
    }

    return this.getVenueFromEdition(edition);
  }

  setVenue(venue: Venue) {
    this.venue = venue;
    this.venueSubject.next(venue);
  }

  getVenueSubject(): Observable<Venue> {
    return this.venueSubject.asObservable();
  }

  // ------------ Availability ------------

  setAvailability(availability: Availability) {
    this.availability = availability;
    this.availabilitySubject.next(availability);
  }

  getAvailabilitySubject(): Observable<Availability> {
    return this.availabilitySubject.asObservable();
  }

  getAvailability() {
    return this.availability;
  }

  // ------------ HTTP requests ------------

  private getVenueFromEdition(edition: String): Observable<Venue> {
    return this.sponsorsService.getVenueFromEdition(edition);
  }

  private getCurrentVenue(): Observable<Venue> {
    return this.sponsorsService.getCurrentVenue();
  }

  uploadStand(stand: Stand): Observable<Venue> {
    return this.sponsorsService.uploadStand(stand);
  }

  deleteStand(id: number): Observable<Venue> {
    return this.sponsorsService.deleteStand(id);
  }
}
