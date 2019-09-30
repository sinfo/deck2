import { Component } from '@angular/core';

import { SpeakersService } from '../../../deck-api/speakers.service';
import { EditFormCommunicatorService, AppliedForm } from '../edit-form-communicator.service';

import { AddSpeakerForm } from '../../../models/speaker';

@Component({
    selector: 'app-add-speaker-form',
    templateUrl: './add-speaker-form.component.html',
    styleUrls: ['./add-speaker-form.component.css']
})
export class AddSpeakerFormComponent {

    form: AddSpeakerForm;

    constructor(
        private editFormCommunicatorService: EditFormCommunicatorService,
        private speakersService: SpeakersService
    ) {
        this.form = new AddSpeakerForm();
    }

    submitNewSpeaker() {
        if (!this.form.valid()) { return; }

        this.speakersService.createSpeaker(this.form).subscribe(() => {
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.AddSpeaker);
            this.editFormCommunicatorService.closeForm();
        });
    }

}
