import { Component } from '@angular/core';
import { Router } from '@angular/router';

import { SpeakersService } from '../../../deck-api/speakers.service';
import { EditFormCommunicatorService, AppliedForm } from '../edit-form-communicator.service';

import { AddSpeakerForm, Speaker } from '../../../models/speaker';

@Component({
    selector: 'app-add-speaker-form',
    templateUrl: './add-speaker-form.component.html',
    styleUrls: ['./add-speaker-form.component.css']
})
export class AddSpeakerFormComponent {

    form: AddSpeakerForm;

    constructor(
        private editFormCommunicatorService: EditFormCommunicatorService,
        private speakersService: SpeakersService,
        private router: Router
    ) {
        this.form = new AddSpeakerForm();
    }

    submitNewSpeaker() {
        if (!this.form.valid()) { return; }

        this.speakersService.createSpeaker(this.form).subscribe((speaker: Speaker) => {
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.AddSpeaker);
            this.editFormCommunicatorService.closeForm();
            this.router.navigate(["/speakers/"+speaker.id]);
        });
    }

}
