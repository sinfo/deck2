import { FormGroup, FormControl, FormArray, FormBuilder, Validators } from '@angular/forms';

export class Contact {
    id: String;
    phones: ContactPhones[];
    socials: ContactSocials;
    mails: ContactMail[];
}

export class ContactPhones {
    phone: String;
    valid: Boolean;
}

export class ContactSocials {
    facebook: String;
    skype: String;
    github: String;
    twitter: String;
    linkedin: String;
}

export class ContactMail {
    mail: String;
    personal: Boolean;
    valid: Boolean;
}

export class EditContactForm {

    contactId: String;
    form: FormGroup;

    constructor(
        private formBuilder: FormBuilder
    ) { }

    setContact(contact: Contact) {
        this.contactId = contact.id;

        this.form = this.formBuilder.group({
            mails: this.formBuilder.array([]),
            socials: this.formBuilder.group({
                facebook: new FormControl(contact.socials.facebook || '', []),
                github: new FormControl(contact.socials.github || '', []),
                linkedin: new FormControl(contact.socials.linkedin || '', []),
                skype: new FormControl(contact.socials.skype || '', []),
                twitter: new FormControl(contact.socials.twitter || '', []),
            }),
            phones: this.formBuilder.array([]),
        });


        for (const mail of contact.mails) {
            this.pushMail(mail);
        }

        for (const phone of contact.phones) {
            this.pushPhone(phone);
        }
    }

    ready() {
        return this.contactId !== undefined;
    }

    value() {
        return this.form.value;
    }

    valid() {
        return this.contactId !== undefined && this.form.valid;
    }

    pushMail(mail?: ContactMail) {
        const mails = this.form.get('mails') as FormArray;

        if (mail) {
            mails.push(this.formBuilder.group({
                mail: new FormControl(mail.mail, [Validators.required, Validators.email]),
                personal: new FormControl(mail.personal, [Validators.required]),
                valid: new FormControl(mail.valid, [Validators.required]),
            }));
        } else {
            mails.push(this.formBuilder.group({
                mail: new FormControl('', [Validators.required, Validators.email]),
                personal: new FormControl(false, [Validators.required]),
                valid: new FormControl(true, [Validators.required]),
            }));
        }
    }

    pushPhone(phone?: ContactPhones) {
        const phones = this.form.get('phones') as FormArray;

        if (phone) {
            phones.push(this.formBuilder.group({
                phone: new FormControl(phone.phone, [Validators.required, Validators.minLength(1)]),
                valid: new FormControl(true, [Validators.required]),
            }));
        } else {
            phones.push(this.formBuilder.group({
                phone: new FormControl('', [Validators.required, Validators.minLength(1)]),
                valid: new FormControl(true, [Validators.required]),
            }));
        }
    }

}
