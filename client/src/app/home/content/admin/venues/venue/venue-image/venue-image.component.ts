import { Component, OnInit, OnDestroy, Input, Output, EventEmitter } from '@angular/core';

import { Subscription } from 'rxjs/internal/Subscription';

import { VenuesService } from '../../../services/venues.service';
import { CanvasService } from '../../../services/canvas.service';

import { Venue } from '../../../models/venue';
import { Stand } from 'src/app/views/admin/venues/venue/stand';
import { CanvasState, CanvasActionCommunication, CanvasAction } from '../../../models/canvasCommunication';

@Component({
  selector: 'app-venue-image',
  templateUrl: './venue-image.component.html',
  styleUrls: ['./venue-image.component.css']
})
export class VenueImageComponent implements OnInit, OnDestroy {

  private venueSubscription: Subscription;
  private canvasSubscription: Subscription;

  venue: Venue;

  @Input() maxWidth;
  @Input() maxHeight;
  @Input() state: CanvasState;
  @Output() standClick: EventEmitter<Stand> = new EventEmitter();

  private loadingSrc = 'assets/img/loading.gif';
  private canvasOn = false;

  constructor(
    private venuesService: VenuesService,
    private canvasService: CanvasService
  ) { }

  ngOnInit() {
    if (this.maxWidth === undefined && this.maxHeight === undefined) {
      this.maxWidth = 50;
    }

    this.venueSubscription = this.venuesService.getVenueSubject()
      .subscribe(venue => this.venue = venue);

    this.canvasSubscription = this.canvasService.getCommunicationSubject()
      .subscribe((comm: CanvasActionCommunication) => {
        switch (comm.action) {
          case CanvasAction.ON:
            this.canvasOn = true;
            break;

          case CanvasAction.OFF:
            this.canvasOn = false;
            break;

          case CanvasAction.CLEAR:
            this.canvasOn = false;
            break;
        }
      });
  }

  ngOnDestroy() {
    this.venueSubscription.unsubscribe();
    this.canvasSubscription.unsubscribe();
  }

  public standClickCanvas(event) {
    this.standClick.emit(event);
  }

  private canvasStateSetup() {
    this.canvasService.setup();
  }
}
