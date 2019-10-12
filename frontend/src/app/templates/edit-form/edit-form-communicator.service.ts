import { Injectable } from '@angular/core';

import { Observable } from 'rxjs/internal/Observable';
import { ReplaySubject } from 'rxjs/internal/ReplaySubject';

export enum AppliedForm {
    EditSpeaker,
    EditSpeakerInternalImage,
    EditSpeakerPublicImage,
    EditSpeakerCompanyImage,
    EditSpeakerParticipation,
    EditSpeakerContact,
    EditSpeakerParticipationStepStatus,
    EditSpeakerParticipationStatus,
    AddSpeaker,
    AddItem,
    AddTeam,
    AddMemberToTeam,
}

export type AppliedFormCallback = (appliedForm: AppliedForm) => void;

@Injectable({
    providedIn: 'root'
})
export class EditFormCommunicatorService {

    private formSubject: ReplaySubject<any> = new ReplaySubject<any>();
    private appliedFormSubject: ReplaySubject<AppliedForm> = new ReplaySubject<AppliedForm>();
    public data: any;

    constructor() {
    }

    subscribeCallback(callback: AppliedFormCallback): void {
        this.appliedFormSubject.subscribe(callback);
    }

    getSubscription(): Observable<any> {
        return this.formSubject.asObservable();
    }

    setAppliedForm(appliedForm: AppliedForm) {
        this.appliedFormSubject.next(appliedForm);
    }

    setForm(form) {
        this.formSubject.next(form);
    }

    closeForm() {
        this.formSubject.next(null);
    }

}
