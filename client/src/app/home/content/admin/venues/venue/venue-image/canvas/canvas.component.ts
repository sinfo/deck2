import {
  Component, OnInit, OnDestroy,
  ElementRef, ViewChild,
  Input, Output, EventEmitter, DoCheck
} from '@angular/core';

import { fromEvent } from 'rxjs';
import { switchMap, takeUntil, tap } from 'rxjs/operators';
import { Subscription } from 'rxjs/internal/Subscription';

import { VenuesService } from '../../../../services/venues.service';
import { CanvasService } from '../../../../services/canvas.service';
import { ReservationsService } from 'src/app/views/admin/reservations/reservations.service';

import {
  CanvasState, CanvasAction, CanvasActionCommunication, Selected, CanvasData
} from '../../../../models/canvasCommunication';

import { Stand } from '../../../../models/stand';
import { Reservation } from 'src/app/views/admin/reservations/reservation/reservation';

@Component({
  selector: 'app-canvas',
  templateUrl: './canvas.component.html',
  styleUrls: ['./canvas.component.css']
})
export class CanvasComponent implements OnInit, OnDestroy, DoCheck {

  @ViewChild('canvas') public canvas: ElementRef;
  private canvasBounds;
  public standHover = false;

  @Input() state: CanvasState;
  @Output() standClickCanvas: EventEmitter<Stand> = new EventEmitter();

  private venueSubscription: Subscription;
  private commSubscription: Subscription;
  private reservationSubscription: Subscription;
  private canvasEventsSubscription: Subscription;

  private data: CanvasData;

  private startingPoint: { x: number, y: number };

  private cx: CanvasRenderingContext2D;

  constructor(
    private venuesService: VenuesService,
    private canvasService: CanvasService,
    private reservationsService: ReservationsService
  ) { }

  ngOnInit() {
    this.data = new CanvasData(this.state);

    this.venueSubscription = this.venuesService.getVenueSubject()
      .subscribe(venue => {
        if (venue) {
          this.data.updateStands(venue);
        }

        if (this.cx) {
          this.clearCanvas();
          this.drawStands();
        }

      });

    this.reservationSubscription = this.reservationsService.getReservationSubject()
      .subscribe(reservation => {
        this.data.reservation = new Reservation(reservation);

        if (this.cx) {
          this.clearCanvas();
          this.drawStands();
        }
      });

    this.venuesService.getAvailabilitySubject()
      .subscribe(availability => {
        if (this.data.availability) {
          this.data.availability.value = availability;
        }
      });

    this.initCommunicationHandler();
  }

  ngOnDestroy() {
    this.canvasService.cancelNewStand();
    this.venueSubscription.unsubscribe();
    this.commSubscription.unsubscribe();
    this.reservationSubscription.unsubscribe();
  }

  ngDoCheck() {
    this.canvasBounds = this.canvas.nativeElement.getBoundingClientRect();
  }

  // highlight and select stand on mouseover
  public standHoverHandler(event) {
    let found = false;

    event.preventDefault();
    this.clearCanvas();
    this.drawStands();

    // get the mouse position
    const mouseX = (event.clientX - this.canvasBounds.left) / this.canvasBounds.width;
    const mouseY = (event.clientY - this.canvasBounds.top) / this.canvasBounds.height;

    for (const stand of this.data.stands) {
      const left = stand.topLeft.x;
      const right = stand.bottomRight.x;
      const top = stand.topLeft.y;
      const bottom = stand.bottomRight.y;

      if (mouseX > left && mouseX < right && mouseY < top && mouseY > bottom) {
        found = true;

        const color = this.data.getColor(stand, true);
        this.drawStand(stand, color);
        break;
      }
    }

    this.standHover = found;
  }

  // highlight and select stand on mouseover
  public standClickHandler(event) {
    event.preventDefault();

    // get the mouse position
    const mouseX = (event.clientX - this.canvasBounds.left) / this.canvasBounds.width;
    const mouseY = (event.clientY - this.canvasBounds.top) / this.canvasBounds.height;

    for (const stand of this.data.stands) {
      const left = stand.topLeft.x;
      const right = stand.bottomRight.x;
      const top = stand.topLeft.y;
      const bottom = stand.bottomRight.y;

      if (mouseX > left && mouseX < right && mouseY < top && mouseY > bottom) {
        this.standClickCanvas.emit(stand);
        break;
      }
    }
  }

  private initCommunicationHandler() {
    this.commSubscription = this.canvasService.getCommunicationSubject()
      .subscribe((communication: CanvasActionCommunication) => {
        switch (communication.action) {
          case CanvasAction.SETUP:
            this.setup();
            this.drawStands();
            break;

          case CanvasAction.ON:
            if (this.cx) {
              this.start();
            }
            break;

          case CanvasAction.OFF:
            if (this.cx) {
              this.stop();
            }
            break;

          case CanvasAction.REVERT:
            if (this.cx) {
              this.clearCanvas();
              communication.selected && communication.selected.stand
                ? this.drawStands(communication.selected.stand)
                : this.drawStands();
            }
            break;

          case CanvasAction.SELECT_DAY:
            this.data.availability.selectedDay = communication.selected.day;

            if (this.cx) {
              this.clearCanvas();
              this.drawStands();
            }

            break;

          case CanvasAction.SELECT:
            const stand = communication.selected.stand;

            if (this.cx) {
              this.clearCanvas();
              const color = this.data.getColor(stand, true);
              this.drawStand(stand, color);
            }

            break;

          case CanvasAction.SELECT_TO_DELETE:
            if (this.cx) {
              this.clearCanvas();
              this.drawStand(communication.selected.stand, CanvasData.COLOR_DELETE.DEFAULT);
            }
            break;

          case CanvasAction.CLEAR:
            if (this.cx) {
              this.data.clear();
              this.clearCanvas();
            }
            break;
        }
      });
  }

  private drawStand(stand: Stand, color: string) {
    const pos1 = this.convertPosToAbsolute(stand.topLeft);
    const pos2 = this.convertPosToAbsolute(stand.bottomRight);

    this.cx.strokeStyle = color;

    this.drawRect(pos1, pos2);
  }

  private drawStands(selectedStand?: Stand) {
    const stands = this.data.pendingStand
      ? this.data.stands.concat([this.data.pendingStand])
      : this.data.stands;

    for (const stand of stands) {
      const selected = selectedStand && selectedStand.id === stand.id;

      const color = this.data.getColor(stand, selected);

      this.drawStand(stand, color);
    }
  }

  private setup() {
    const canvasEl: HTMLCanvasElement = this.canvas.nativeElement;
    this.cx = canvasEl.getContext('2d');

    canvasEl.width = this.canvas.nativeElement.offsetWidth;
    canvasEl.height = this.canvas.nativeElement.offsetHeight;

    this.cx.lineWidth = 3;
    this.cx.lineCap = 'round';
  }

  private stop() {
    if (this.canvasEventsSubscription) {
      this.canvasEventsSubscription.unsubscribe();
    }
  }

  private start() {
    const canvasEl: HTMLCanvasElement = this.canvas.nativeElement;
    this.canvasEventsSubscription = fromEvent(canvasEl, 'mousedown')
      .pipe(
        tap(start => this.captureFirstPoint(canvasEl, start)),
        switchMap(e => {
          return fromEvent(canvasEl, 'mousemove')
            .pipe(
              takeUntil(fromEvent(canvasEl, 'mouseup').pipe(
                tap(end => this.captureLastPoint(canvasEl, end))
              )),
              takeUntil(fromEvent(canvasEl, 'mouseleave').pipe(
                tap(end => this.captureLastPoint(canvasEl, end))
              ))
            );
        })
      ).subscribe((mouse: MouseEvent) => {
        const rect = canvasEl.getBoundingClientRect();

        // previous and current position with the offset
        const currentPos = {
          x: mouse.clientX - rect.left,
          y: mouse.clientY - rect.top
        };

        this.drawNewRect(this.startingPoint, currentPos);
      });
  }

  private captureFirstPoint(canvasEl: HTMLCanvasElement, event: Event) {
    const mouse: MouseEvent = <MouseEvent>event;
    const rect = canvasEl.getBoundingClientRect();

    this.data.pendingStand = undefined;

    const pos = {
      x: mouse.clientX - rect.left,
      y: mouse.clientY - rect.top
    };

    this.startingPoint = pos;
  }

  private captureLastPoint(canvasEl: HTMLCanvasElement, event: Event) {
    const mouse: MouseEvent = <MouseEvent>event;
    const rect = canvasEl.getBoundingClientRect();

    const pos = {
      x: mouse.clientX - rect.left,
      y: mouse.clientY - rect.top
    };

    const stand: Stand = new Stand({
      pos1: this.convertPosToRelative(this.startingPoint),
      pos2: this.convertPosToRelative(pos)
    });

    this.data.pendingStand = stand;
    this.canvasService.addNewStand(stand);
  }

  private clearCanvas() {
    this.cx.clearRect(
      0, 0,
      this.canvas.nativeElement.offsetWidth, this.canvas.nativeElement.offsetHeight
    );
  }

  private drawNewRect(
    pos1: { x: number, y: number },
    pos2: { x: number, y: number }
  ) {
    this.clearCanvas();
    this.drawStands();
    this.drawRect(pos1, pos2);
  }

  private drawRect(
    pos1: { x: number, y: number },
    pos2: { x: number, y: number }
  ) {
    // incase the context is not set
    if (!this.cx) { return; }

    // start our drawing path
    this.cx.beginPath();

    // we're drawing lines so we need a previous position
    this.cx.moveTo(pos1.x, pos1.y);

    // draws a line from the start pos until the current position
    this.cx.lineTo(pos2.x, pos1.y);
    this.cx.lineTo(pos2.x, pos2.y);
    this.cx.lineTo(pos1.x, pos2.y);
    this.cx.lineTo(pos1.x, pos1.y);

    // strokes the current path with the styles we set earlier
    this.cx.stroke();
    this.cx.strokeStyle = null;
  }

  private convertPosToRelative(pos: { x: number, y: number }) {
    const w = this.canvas.nativeElement.offsetWidth;
    const h = this.canvas.nativeElement.offsetHeight;

    return { x: pos.x / w, y: pos.y / h };
  }

  private convertPosToAbsolute(pos: { x: number, y: number }) {
    const w = this.canvas.nativeElement.offsetWidth;
    const h = this.canvas.nativeElement.offsetHeight;

    return { x: pos.x * w, y: pos.y * h };
  }

}
