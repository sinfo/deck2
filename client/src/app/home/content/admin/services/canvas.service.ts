import { Injectable } from '@angular/core';

import { Observable } from 'rxjs/internal/Observable';
import { BehaviorSubject } from 'rxjs/internal/BehaviorSubject';
import { ReplaySubject } from 'rxjs/internal/ReplaySubject';

import {
  CanvasActionCommunication,
  CanvasState, CanvasAction, Selected
} from '../models/canvasCommunication';

import { Stand } from '../models/stand';

@Injectable({
  providedIn: 'root'
})
export class CanvasService {

  private commActionSubject = new BehaviorSubject<CanvasActionCommunication>(
    new CanvasActionCommunication(CanvasAction.OFF)
  );

  private newStandSubject = new ReplaySubject<Stand>();

  constructor() { }

  // --------- Actions --------

  setup() {
    const comm = this.buildCanvasActionCommunication(CanvasAction.SETUP);
    this.commActionSubject.next(comm);
  }

  on() {
    const comm = this.buildCanvasActionCommunication(CanvasAction.ON);
    this.commActionSubject.next(comm);
  }

  off() {
    const comm = this.buildCanvasActionCommunication(CanvasAction.OFF);
    this.commActionSubject.next(comm);
  }

  revert(selectedStand?: Stand) {
    const comm = this.buildCanvasActionCommunication(CanvasAction.REVERT, { stand: selectedStand });
    this.commActionSubject.next(comm);
  }

  clear() {
    const comm = this.buildCanvasActionCommunication(CanvasAction.CLEAR);
    this.commActionSubject.next(comm);
  }

  selectDay(day: number) {
    const comm = this.buildCanvasActionCommunication(CanvasAction.SELECT_DAY, { day: day });
    this.commActionSubject.next(comm);
  }

  select(selectedStand: Stand) {
    const comm = this.buildCanvasActionCommunication(CanvasAction.SELECT, { stand: selectedStand });
    this.commActionSubject.next(comm);
  }

  selectToDelete(selectedStand: Stand) {
    const comm = this.buildCanvasActionCommunication(CanvasAction.SELECT_TO_DELETE, { stand: selectedStand });
    this.commActionSubject.next(comm);
  }

  getCommunicationSubject(): Observable<CanvasActionCommunication> {
    return this.commActionSubject.asObservable();
  }

  addNewStand(stand: Stand) {
    this.newStandSubject.next(stand);
  }

  cancelNewStand() {
    this.newStandSubject.next(undefined);
  }

  getNewStandSubject(): Observable<Stand> {
    return this.newStandSubject.asObservable();
  }

  private buildCanvasActionCommunication(state: CanvasAction, selected?: Selected) {
    const comm = selected
      ? new CanvasActionCommunication(state, selected)
      : new CanvasActionCommunication(state);

    return comm;
  }
}
