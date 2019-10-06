import { Component, OnInit, OnDestroy } from '@angular/core';

import { Subscription } from 'rxjs/internal/Subscription';

import { DeckService } from 'src/app/services/deck.service';
import { LinksService } from 'src/app/views/admin/links/links.service';

import { Companies } from '../models/companies';
import { Company } from 'src/app/models/company';

import { Event } from 'src/app/models/event';
import { Link } from 'src/app/views/admin/links/link/link';

@Component({
  selector: 'app-links',
  templateUrl: './links.component.html',
  styleUrls: ['./links.component.css']
})
export class LinksComponent implements OnInit, OnDestroy {

  event: Event;
  companies: Companies;

  eventSubscription: Subscription;
  companiesSubscription: Subscription;

  constructor(
    private deckService: DeckService,
    private linksService: LinksService
  ) { }

  ngOnInit() {
    this.companies = new Companies();

    this.eventSubscription = this.deckService.getEventSubject()
      .subscribe(event => this.event = event);

    this.companiesSubscription = this.linksService.getCompaniesSubscription()
      .subscribe(companies => this.companies = companies);
  }

  ngOnDestroy() {
    this.companiesSubscription.unsubscribe();
    this.eventSubscription.unsubscribe();
  }

  invalidate(link: Link) {
    const company = this.companies.withLink.valid
      .filter(c => c.id !== link.companyId)[0];

    this.companies.withLink.valid = this.companies.withLink.valid
      .filter(() => company.id !== company.id) as Company[];

    this.companies.withLink.invalid.push(company);
  }

}
