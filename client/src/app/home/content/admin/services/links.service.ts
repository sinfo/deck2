import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

import { Observable } from 'rxjs/internal/Observable';
import { ReplaySubject } from 'rxjs/internal/ReplaySubject';
import { Subscription } from 'rxjs/internal/Subscription';

import { StorageService } from '../../../storage.service';

import { DeckService } from 'src/app/services/deck.service';

import { Link, LinkForm, LinkEdit } from '../models/link';
import { Companies } from '../models/companies';
import { Company } from 'app/models/company';
import { Event } from 'app/models/event';
import { SponsorsService } from '../../../services/sponsors.service';

@Injectable({
  providedIn: 'root'
})
export class LinksService {
  companies: Companies;
  event: Event;
  eventSubscription: Subscription;
  deckCompaniesSubscription: Subscription;

  private companiesSubject: ReplaySubject<Companies> = new ReplaySubject<Companies>();

  constructor(
    private http: HttpClient,
    private storage: StorageService,
    private deckService: DeckService,
    private sponsorsService: SponsorsService
  ) {
    this.companies = new Companies();

    this.eventSubscription = this.deckService.getEventSubject()
      .subscribe(event => {
        const eventOverride = this.event !== undefined && this.event.id !== event.id;
        this.event = event;
        if (eventOverride) { this.updateLinks(event.id as string); }
      });

    this.deckCompaniesSubscription = this.deckService.getDeckCompaniesSubject()
      .subscribe(companies => {
        this.companies.updateCompanies(companies, this.event.id);
        this.updateLinks();
      });
  }

  getCompaniesSubscription(): Observable<Companies> {
    return this.companiesSubject.asObservable();
  }

  updateLinks(edition?: string) {
    edition
      ? this.getLinks({ edition: edition }).subscribe(links => {
        const l = links instanceof Link ? [links] as Link[] : links as Link[];
        this.companies.updateLinks(l);
        this.companiesSubject.next(this.companies);
      })
      : this.verifyAndGetLinks().subscribe(links => {
        this.companies.updateLinks(links);
        this.companiesSubject.next(this.companies);
      });

  }

  uploadLink(form: LinkForm): Observable<Link> {
    return this.sponsorsService.uploadLink(form);
  }

  getLinks(filter?: {
    companyId?: string,
    edition?: string,
    token?: string
  }): Observable<Link | Link[]> {
    return this.sponsorsService.getLinks(filter);
  }

  verifyAndGetLinks(): Observable<Link[]> {
    return this.sponsorsService.verifyAndGetLinks();
  }

  // TODO why is it unused
  getCompaniesWithMissingLinks(): Observable<Company[]> {
    return this.sponsorsService.getCompaniesWithMissingLinks();
  }

  extend(companyId: String, edition: String, form: { expirationDate: Date }): Observable<Link> {
    return this.sponsorsService.extend(companyId, edition, form);
  }

  edit(form: LinkEdit, event: Event, companyId: String): Observable<Link> {
    return this.sponsorsService.edit(form, event, companyId);
  }

  revoke(companyId: String, edition: String): void {
    this.sponsorsService.revoke(companyId, edition).subscribe(() => {
      this.updateLinks(edition as string);
    });
  }

  check(companyId: String): Observable<{ expirationDate: Date }> {
    return this.sponsorsService.check(companyId);
  }
}
