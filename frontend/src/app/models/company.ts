import { FormControl, FormGroup, Validators } from '@angular/forms';
import { CompaniesService } from '../deck-api/companies.service';

export class Company {
    id: String;
    name: String;
    description: String;
    imgs: CompanyImages;
    site: String;
    employers: String[];
    billingInfo: CompanyBillingInfo;
    participations: CompanyParticipation[];
}

export class CompanyImages {
    internal: String;
    public: String;
}

export class CompanyBillingInfo {
    name: String;
    address: String;
    tin: String;
}

export class CompanyParticipation {
    event: Number;
    member: String;
    status: String;
    communications: String[]
    subscribers: String[];
    billing: String;
    package: String;
    confirmed: Date;
    partner: Boolean;
    notes: String;
}

export class CompanyParticipationValidStatusStep {
    next: String;
    step: Number;
}

export class CompanyParticipationValidStatusSteps {
    steps: CompanyParticipationValidStatusStep[];
}

export function GetParticipation(company: Company, event: Number): CompanyParticipation {
    for (const participation of company.participations) {
        if (participation.event === event) {
            return participation;
        }
    }

    return null;
}
export class AddCompanyForm {

    form: FormGroup;

    constructor() {
        this.form = new FormGroup({
            name: new FormControl('', [Validators.required, Validators.minLength(1)]),
            site: new FormControl('', []),
            description: new FormControl('', [Validators.required, Validators.minLength(1)]),
        });
    }

    value() {
        return this.form.value;
    }

    valid() {
        return this.form.valid;
    }
}