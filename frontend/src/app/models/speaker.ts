import { FormControl, FormGroup, Validators } from '@angular/forms';
import { SpeakersService } from '../deck-api/speakers.service';

export class Speaker {
    id: String;
    name: String;
    contact: String;
    title: String;
    bio: String;
    notes: String;
    imgs: SpeakerImages;
    participations: SpeakerParticipation[];
}

export class SpeakerImages {
    internal: String;
    speaker: String;
    company: String;
}

export class SpeakerParticipation {
    event: Number;
    member: String;
    status: String;
    communications: String[];
    subscribers: String[];
    feedback: String;
    flights: String[];
    room: SpeakerParticipationRoom;
}

export class SpeakerParticipationRoom {
    type: String;
    cost: Number;
    notes: String;
}

export class SpeakerParticipationValidStatusStep {
    next: String;
    step: Number;
}

export class SpeakerParticipationValidStatusSteps {
    steps: SpeakerParticipationValidStatusStep[];
}

export function GetParticipation(speaker: Speaker, event: Number): SpeakerParticipation {
    for (const participation of speaker.participations) {
        if (participation.event === event) {
            return participation;
        }
    }

    return null;
}

export class EditSpeakerForm {

    form: FormGroup;

    constructor(speaker: Speaker) {
        this.form = new FormGroup({
            bio: new FormControl(speaker.bio ? speaker.bio : '', [Validators.required, Validators.minLength(1)]),
            name: new FormControl(speaker.name, [Validators.required, Validators.minLength(1)]),
            notes: new FormControl(speaker.notes, [Validators.required, Validators.minLength(1)]),
            title: new FormControl(speaker.title, [Validators.required, Validators.minLength(1)]),
        });
    }

    value() {
        return this.form.value;
    }

    valid() {
        return this.form.valid;
    }

}
export class AddSpeakerForm {

    form: FormGroup;

    constructor() {
        this.form = new FormGroup({
            name: new FormControl('', [Validators.required, Validators.minLength(1)]),
            bio: new FormControl('', []),
            title: new FormControl('', [Validators.required, Validators.minLength(1)]),
        });
    }

    value() {
        return this.form.value;
    }

    valid() {
        return this.form.valid;
    }
}

export class EditSpeakerParticipationForm {

    form: FormGroup;

    constructor(participation?: SpeakerParticipation) {
        this.form = new FormGroup({
            feedback: new FormControl(participation ? participation.feedback : '', []),
            member: new FormControl(participation ? participation.member : '', [Validators.required, Validators.minLength(1)]),
            room: new FormGroup({
                cost: new FormControl(participation && participation.room ? participation.room.cost : 0, [Validators.required, Validators.min(0)]),
                notes: new FormControl(participation && participation.room ? participation.room.notes : '', []),
                type: new FormControl(participation && participation.room ? participation.room.type : '', []),
            })
        });
    }

    value() {
        return this.form.value;
    }

    valid() {
        return this.form.valid;
    }
}

export class EditSpeakerImageForm {

    form: FormGroup;
    file: File;

    constructor() {
        this.form = new FormGroup({
            image: new FormControl(null, [Validators.required]),
        });
    }

    value() {
        return this.file;
    }

    valid() {
        return this.form.valid;
    }

    set(file: File) {
        this.file = file;
    }
}

export class EditSpeakerParticipationStatusForm {

    form: FormGroup;
    options: SpeakerParticipationValidStatusSteps;
    speaker: Speaker;
    label: String;

    constructor(private speakersService: SpeakersService, speaker: Speaker, participation?: SpeakerParticipation) {
        this.form = new FormGroup({
            step: new FormControl('', [Validators.required, Validators.minLength(1)]),
        });

        this.speaker = speaker;

        this.updateOptions(participation);
    }

    updateOptions(participation: SpeakerParticipation) {
        if (participation === undefined || participation === null) { return; }

        this.speakersService.getValidStatusSteps(`${this.speaker.id}`)
            .subscribe((steps: SpeakerParticipationValidStatusSteps) => {
                this.options = steps;
            }
            );
    }

    set(step: SpeakerParticipationValidStatusStep) {
        this.form.controls['step'].setValue(step.step);
        this.label = step.next;
    }

    valid() {
        return this.form.valid;
    }

    value() {
        return this.form.get('step').value;
    }
}
