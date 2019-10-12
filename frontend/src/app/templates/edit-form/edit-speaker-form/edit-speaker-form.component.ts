import { Component } from '@angular/core';
import { FormBuilder } from '@angular/forms';

import { AppliedForm, EditFormCommunicatorService } from '../edit-form-communicator.service';

import {
    EditSpeakerForm,
    EditSpeakerImageForm,
    EditSpeakerParticipationForm,
    GetParticipation,
    Speaker,
    SpeakerParticipation,
    EditSpeakerParticipationStatusForm,
    SpeakerParticipationValidStatusStep,
    EditSpeakerParticipationStatusAdminForm
} from '../../../models/speaker';
import { Event } from '../../../models/event';
import { EditContactForm, Contact } from '../../../models/contact';
import { CoordinatorAccessLevel, Role } from '../../../models/role';

import { SpeakersService } from '../../../deck-api/speakers.service';
import { MeService } from '../../../deck-api/me.service';
import { EventsService } from '../../../deck-api/events.service';
import { ContactsService } from '../../../deck-api/contacts.service';

@Component({
    selector: 'app-edit-speaker-form',
    templateUrl: './edit-speaker-form.component.html',
    styleUrls: ['./edit-speaker-form.component.css']
})
export class EditSpeakerFormComponent {

    event: Event;
    role: Role;
    speaker: Speaker;
    participation: SpeakerParticipation;

    forms: {
        speaker: EditSpeakerForm,
        image: {
            internal: EditSpeakerImageForm,
            speaker: EditSpeakerImageForm,
            company: EditSpeakerImageForm
        },
        participation: EditSpeakerParticipationForm,
        contact: EditContactForm,
        stepStatus: EditSpeakerParticipationStatusForm,
        status: EditSpeakerParticipationStatusAdminForm
    };

    constructor(
        private formBuilder: FormBuilder,
        private editFormCommunicatorService: EditFormCommunicatorService,
        private speakersService: SpeakersService,
        private eventsService: EventsService,
        private contactsService: ContactsService,
        private meService: MeService
    ) {
        this.speaker = this.editFormCommunicatorService.data;

        this.forms = {
            speaker: new EditSpeakerForm(this.speaker),
            image: {
                internal: new EditSpeakerImageForm(),
                speaker: new EditSpeakerImageForm(),
                company: new EditSpeakerImageForm(),
            },
            participation: new EditSpeakerParticipationForm(),
            contact: new EditContactForm(this.formBuilder),
            stepStatus: new EditSpeakerParticipationStatusForm(this.speakersService, this.speaker),
            status: new EditSpeakerParticipationStatusAdminForm(this.speaker)
        };

        this.meService.getMyRole().subscribe((role: Role) => {
            this.role = role;
        });

        this.updateParticipation();

        this.contactsService.getContact(this.speaker.contact).subscribe((contact: Contact) => {
            this.forms.contact.setContact(contact);
        });
    }

    private updateParticipation() {
        this.eventsService.getCurrentEvent().subscribe((event: Event) => {
            this.participation = GetParticipation(this.speaker, event.id);
            this.event = event;

            if (this.participation != null) {
                this.forms.participation = new EditSpeakerParticipationForm(this.participation);
                this.forms.stepStatus = new EditSpeakerParticipationStatusForm(this.speakersService, this.speaker);
                this.forms.stepStatus.updateOptions(this.participation);
            }
        });

    }

    coordinatorAccessLevel() {
        return CoordinatorAccessLevel(this.role);
    }

    editSpeaker() {
        if (!this.forms.speaker.valid()) {
            return;
        }
        this.speakersService.editSpeaker(`${this.speaker.id}`, this.forms.speaker).subscribe(speaker => {
            this.speaker = speaker;
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeaker);
        });
    }

    editParticipation() {
        if (!this.forms.participation.valid()) {
            return;
        }

        this.speakersService.editSpeakerParticipation(`${this.speaker.id}`, this.forms.participation).subscribe(speaker => {
            this.speaker = speaker;
            this.updateParticipation();
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeakerParticipation);
        });
    }

    addParticipation() {
        this.speakersService.addSpeakerParticipation(`${this.speaker.id}`).subscribe(speaker => {
            this.speaker = speaker;
            this.updateParticipation();
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeakerParticipation);
        });
    }

    editSpeakerInternalImage() {
        if (!this.forms.image.internal.valid()) {
            return;
        }
        this.speakersService.editSpeakerInternalImage(`${this.speaker.id}`, this.forms.image.internal).subscribe(speaker => {
            this.speaker = speaker;
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeakerInternalImage);
        });
    }

    internalImageUploaded(event) {
        if (event.target.files.length > 0) {
            const file = event.target.files[0];
            this.forms.image.internal.set(file);
        }
    }

    speakerImageUploaded(event) {
        if (event.target.files.length > 0) {
            const file = event.target.files[0];
            this.forms.image.speaker.set(file);
        }
    }

    editSpeakerPublicImage() {
        if (!this.forms.image.internal.valid()) {
            return;
        }
        this.speakersService.editSpeakerPublicImage(`${this.speaker.id}`, this.forms.image.internal).subscribe(speaker => {
            this.speaker = speaker;
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeakerPublicImage);
        });
    }

    companyImageUploaded(event) {
        if (event.target.files.length > 0) {
            const file = event.target.files[0];
            this.forms.image.company.set(file);
        }
    }

    editSpeakerCompanyImage() {
        if (!this.forms.image.internal.valid()) {
            return;
        }

        this.speakersService.editSpeakerCompanyImage(`${this.speaker.id}`, this.forms.image.internal).subscribe(speaker => {
            this.speaker = speaker;
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeakerCompanyImage);
        });
    }

    editContact() {
        if (!this.forms.contact.valid()) {
            return;
        }

        this.contactsService.editContact(this.forms.contact).subscribe((contact: Contact) => {
            this.forms.contact.setContact(contact);
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeakerContact);
        });
    }

    changeStepStatus(step: SpeakerParticipationValidStatusStep) {
        this.forms.stepStatus.set(step);
    }

    changeStatus(status: String) {
        this.forms.status.set(status);
    }

    editParticipationStepStatus() {
        if (!this.forms.stepStatus.valid()) {
            return;
        }

        this.speakersService.stepStatus(`${this.speaker.id}`, +this.forms.stepStatus.value()).subscribe((speaker: Speaker) => {
            this.speaker = speaker;
            this.participation = GetParticipation(this.speaker, this.event.id);

            if (this.participation != null) {
                this.forms.stepStatus.updateOptions(this.participation);
            }

            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeakerParticipationStepStatus);
        });

        this.close();
    }

    editParticipationStatus() {
        if (!this.forms.status.valid() && !this.coordinatorAccessLevel())
            return;

        this.speakersService.setStatus(`${this.speaker.id}`, this.forms.status.value()).subscribe((speaker: Speaker) => {
            this.speaker = speaker;
            this.editFormCommunicatorService.setAppliedForm(AppliedForm.EditSpeakerParticipationStatus);
        });

        this.close();
    }

    close() {
        this.editFormCommunicatorService.closeForm();
    }

}
